uuid = require("node-uuid").v4
http = require "http"
url  = require "url"
qs   = require "querystring"
ENV  = process.env

AUTH_HOST       = "readmill.com"
PROXY_DOMAIN    = ENV["PROXY_DOMAIN"]
CLIENT_ID       = ENV["READMILL_CLIENT_ID"]
CLIENT_SECRET   = ENV["READMILL_CLIENT_SECRET"]
CLIENT_CALLBACK = ENV["READMILL_CLIENT_CALLBACK"]

throw "Requires PROXY_DOMAIN environment variable" unless PROXY_DOMAIN
throw "Requires READMILL_CLIENT_ID environment variable" unless CLIENT_ID
throw "Requires READMILL_CLIENT_SECRET environment variable" unless CLIENT_SECRET
throw "Requires READMILL_CLIENT_CALLBACK environment variable" unless CLIENT_CALLBACK 

callbacks = {}

decorateWithCORS = (res) ->
  headers =
    "Access-Control-Allow-Origin": "*"
    "Access-Control-Allow-Methods": "HEAD, GET, POST, PUT, DELETE"
    "Access-Control-Max-Age": 60 * 60
    "Access-Control-Allow-Credentials": false
    "Access-Control-Allow-Headers": "Origin, Content-Type, Accept, Authorization"
    "Access-Control-Expose-Headers": "Location, Content-Type, Expires"

  res.setHeader(key, value) for own key, value of headers
  res

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
    client_id: CLIENT_ID
    client_secret: CLIENT_SECRET
    redirect_uri: "#{PROXY_DOMAIN}/callback?callback_id=#{callback_id}"
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

  # Fail early if callback uri is invalid.
  unless CLIENT_CALLBACK.split("?")[0] is query["redirect_uri"].split("?")[0]
    res.writeHead 400
    res.end()
    return

  id = uuid()
  callbacks[id] = query.redirect_uri
  query.redirect_uri = "#{PROXY_DOMAIN}/callback?callback_id=#{id}"
  query.scope = "non-expiring"

  location = url.format
    host: AUTH_HOST
    query: query
    pathname: pathname

  res.writeHead 303, "Location": location
  res.end()

server = http.createServer (req, res) ->
  parsed = url.parse req.url
  if req.method.toLowerCase() == "options"
    res.setHeader("Content-Length", 0)
    decorateWithCORS(res).end()
  else if parsed.pathname.indexOf("/oauth/authorize") is 0
    authorize req, res
  else if parsed.pathname.indexOf("/callback") is 0
    authCallback req, res

server.listen(process.env["PORT"] || 8000)
