uuid = require("node-uuid").v4
http = require "http"
url  = require "url"
qs   = require "querystring"

API_HOST      = "api.readmill.com"
AUTH_HOST     = "readmill.com"
PROXY_DOMAIN  = process.env["PROXY_DOMAIN"]
CLIENT_SECRET = process.env["READMILL_CLIENT_SECRET"]

throw "Requires PROXY_DOMAIN environment variable" unless PROXY_DOMAIN
throw "Requires READMILL_CLIENT_SECRET environment variable" unless CLIENT_SECRET

callbacks = {}

decorateWithCORS = (res) ->
  headers =
    "Access-Control-Allow-Origin": "*"
    "Access-Control-Allow-Methods": "HEAD, GET, POST, PUT, DELETE"
    "Access-Control-Max-Age": 60 * 60
    "Access-Control-Allow-Credentials": false
    "Access-Control-Allow-Headers": "",
    "Access-Control-Expose-Headers": "Location"

  res.setHeader(key, value) for own key, value of headers
  res

proxy = (serverRequest, serverResponse) ->
  {query, pathname} = url.parse serverRequest.url, true

  options =
    host: API_HOST
    path: url.format(pathname: pathname, query: query)
    method: serverRequest.method

  clientRequest = http.request options, (clientResponse) ->
    # Should probably use a Buffer here.
    body = ""

    clientResponse.on "data", (data) -> body += data
    clientResponse.on "end", ->
      serverResponse.setHeader 'Content-Length', body.length
      for own key, value of clientResponse.headers
        if key != 'transfer-encoding'
          key = key.replace /^[a-z]|\-[a-z]/g, (_) -> _.toUpperCase()
          serverResponse.setHeader key, value

      serverResponse.writeHead clientResponse.statusCode
      serverResponse.end body

  for own key, value of serverRequest.headers
    if key != 'host'
      key = key.replace /^[a-z]|\-[a-z]/g, (_) -> _.toUpperCase()
      clientRequest.setHeader key, value

  serverRequest.on "data", clientRequest.write.bind(clientRequest)
  serverRequest.on "end",  clientRequest.end.bind(clientRequest)

  clientRequest

authCallback = (req, res) ->
  {query:{code, error, callback_id}} = url.parse req.url, true

  redirect = callbacks[callback_id]
  delete callbacks[callback_id]

  respond = (hash) ->
    parts = url.parse redirect, true
    parts.hash = hash
    res.writeHead 303, "Location": url.format(parts)
    res.end()

  return respond qs.stringify(error: "proxy-error") unless redirect
  return respond qs.stringify(error: error) if error

  query =
    grant_type: "authorization_code"
    client_id: parts.query.client_id
    client_secret: CLIENT_SECRET
    redirect_uri: "#{PROXY_DOMAIN}/callback?callback_id=#{callback_id}"
    scope:"non-expiring"
    code: code

  queryString = qs.stringify(query)

  options =
    host: AUTH_HOST
    path: "/oauth/token"
    method: "POST"
    headers:
      "Content-Length": queryString.length,
      "Content-Type": "application/x-www-form-urlencoded"

  clientRequest = http.request options, (response) ->
    body = ""

    response.on "data", (data) ->
      body += data

    response.on "end", ->
      json = JSON.parse body
      respond qs.stringify(json)

  clientRequest.on "error", (err) ->
    respond qs.stringify(error: "proxy-error")

  clientRequest.end(queryString)

authorize = (req, res) ->
  {query, pathname} = url.parse req.url, true

  id = uuid()
  callbacks[id] = query.redirect_uri
  query.redirect_uri = "#{PROXY_DOMAIN}/callback?callback_id=#{id}"

  location = url.format
    host: AUTH_HOST
    query: query
    pathname: pathname

  res.writeHead 303, "Location": location
  res.end()

server = http.createServer (req, res) ->
  parsed = url.parse req.url
  if req.method == "options"
    decorateWithCORS(res).end()
  else if parsed.pathname.indexOf("/oauth/authorize") is 0
    authorize req, res
  else if parsed.pathname.indexOf("/callback") is 0
    authCallback req, res
  else
    proxy req, decorateWithCORS(res)

server.listen(process.env["PORT"] || 8000);
