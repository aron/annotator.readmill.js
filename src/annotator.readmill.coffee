class Readmill extends Annotator.Plugin
  @API_ENDPOINT: "http://localhost:8000"

  constructor: (options) ->
    super {}, options

    @auth  = new Readmill.Auth @options
    @store = new Readmill.Store

    token = options.accessToken || @store.get "access-token"
    @connected(token) if token

  connect: ->
    @auth.connect().then @_onConnectSuccess, @_onConnectError

  connected: (accessToken) ->
    @client = new Readmill.Client(accessToken: accessToken)
    @store.set "access-token", accessToken

  _onConnectSuccess: (params) =>
    @connected(params.access_token)

  _onConnectError: (error) =>

utils =
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

class Client
  fetchMe: ->

class Store
  @KEY_PREFIX: "annotator.readmill/"
  @CACHE_DELIMITER: "--cache--"

  @localStorage: window.localStorage

  @now: -> (new Date()).getTime()

  get: (key) ->
    value = Store.localStorage.getItem @prefixed(key)
    if value
      value = @checkCache value
      @remove(key) unless value
    JSON.parse value

  set: (key, value, time) ->
    value = JSON.stringify value
    value = (Store.now() + time) + Store.CACHE_DELIMITER + value if time

    try
      Store.localStorage.setItem @prefixed(key), value
    catch error
      this.trigger 'error', [error, key, value, this]
    this

  remove: (key) ->
    Store.localStorage.removeItem @prefixed(key)
    this

  prefixed: (key) ->
    Store.KEY_PREFIX + key

  checkCache: (value) ->
    if value.indexOf(Store.CACHE_DELIMITER) > -1
      # If the expiry time has passed then return null.
      cached = value.split Store.CACHE_DELIMITER
      value = if Store.now() > cached.shift()
      then null else cached.join(Store.CACHE_DELIMITER)
    value

class Auth
  @AUTH_ENDPOINT: "http://localhost:8000/oauth/authorize"

  constructor: (options) ->
    {@clientId, @callbackUri, @authEndpoint} = options
    @authEndpoint = Auth.AUTH_ENDPOINT unless @authEndpoint

  connect: ->
    params =
      response_type: "code"
      client_id: @clientId
      redirect_uri: @callbackUri
    qs = utils.serializeQueryString(params)

    Auth.callback = @callback

    @popup = @openWindow "#{@authEndpoint}?#{qs}"
    @deferred = new jQuery.Deferred()
    @deferred.promise()

  callback: =>
    hash = @popup.location.hash.slice(1)
    params = qs = utils.parseQueryString(hash)
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

    paramString = utils.serializeQueryString(params, ",")
    window.open url, "readmill-connect", paramString

window.Annotator.Plugin.Readmill = jQuery.extend Readmill,
  Auth: Auth, Store: Store, Client: Client, utils: utils
