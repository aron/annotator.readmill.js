class Readmill extends Annotator.Plugin
  @CLIENT_ID: "454f5cfd1e794930c6fa99a94faad810"
  @API_ENDPOINT: "http://localhost:8000"

Readmill.utils =
  serializeQueryString: (obj, sep="&", eq="=") ->
    esc = window.encodeURIComponent
    ("#{esc(key)}#{eq}#{esc(value)}" for own key, value of obj).join(sep)
  parseQueryString: (str, sep="&", eq="=") ->
    obj = {}
    decode = window.decodeURIComponent
    for param in str.split(sep)
      [key, value] = param.split(eq)
      obj[decode(key)] = decode value
    obj

class Readmill.Auth
  @AUTH_ENDPOINT: "http://localhost:8000/oauth/authorize"
  constructor: (options) ->
    {@clientId, @callbackUri, @authEndpoint} = options
    @authEndpoint = Readmill.Auth.AUTH_ENDPOINT unless @authEndpoint
  connect: ->
    params =
      response_type: "code"
      client_id: @clientId
      redirect_uri: @callbackUri
    qs = Readmill.utils.serializeQueryString(params)

    Readmill.Auth.callback = @callback

    @popup = @openWindow "#{@authEndpoint}?#{qs}"
    @deferred = new jQuery.Deferred()
    @deferred.promise()

  callback: =>
    hash = @popup.location.hash.slice(1)
    params = qs = Readmill.utils.parseQueryString(hash)
    @popup.close()

    if params.access_token
      @deferred.resolve params
    else
      @deferred.reject params.error

  openWindow: (url, width=725, height=575) ->
    left = window.screenX + (window.outerWidth  - width)  / 2
    top  = window.screenY + (window.outerHeight - height) / 2

    params =
      toolbar: no, location: 1, scrollbars: yes
      top: top, left: left, width:  width, height: height

    paramString = Readmill.utils.serializeQueryString(params, ",")
    window.open url, "readmill-connect", paramString

window.Annotator.Plugin.Readmill = Readmill
