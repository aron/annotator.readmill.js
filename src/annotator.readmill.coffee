jQuery = Annotator.$

class Readmill extends Annotator.Plugin
  @API_ENDPOINT: "http://localhost:8000"

  events:
    "annotationCreated": "_onAnnotationCreated"
    "annotationUpdated": "_onAnnotationUpdated"
    "annotationDeleted": "_onAnnotationDeleted"

  constructor: (options) ->
    super

    @user   = null
    @book   = @options.book
    @view   = new Readmill.View
    @auth   = new Readmill.Auth @options
    @store  = new Readmill.Store
    @client = new Readmill.Client @options

    @view.subscribe "connect", @connect

    token = options.accessToken || @store.get "access-token"
    @connected(token, silent: true) if token
    @unsaved = []

  pluginInit: () ->
    jQuery("body").append @view.render()
    @lookupBook().done

  lookupBook: ->
    return @book.deferred if @book.deferred

    @book.deferred = if @book.id
      @client.getBook @book.id
    else
      @client.matchBook @book

    @book.deferred.then(@_onBookSuccess, @_onBookError).done =>
      @view.updateBook @book

  lookupReading: ->
    @lookupBook() unless @book.id
    jQuery.when(@book.deferred).then =>
      data = {state: Readmill.Client.READING_STATE_OPEN}
      request = @client.createReadingForBook @book.id, data
      request.then(@_onCreateReadingSuccess, @_onCreateReadingError)

  connect: =>
    @auth.connect().then @_onConnectSuccess, @_onConnectError

  connected: (accessToken, options) ->
    @client.authorize accessToken
    @client.me().then(@_onMeSuccess, @_onMeError).done =>
      @view.login @user

    @store.set "access-token", accessToken, options.expires

    unless options?.silent is true
      Annotator.showNotification "Successfully connected to Readmill"

  error: (message) ->
    Annotator.showNotification message, Annotator.Notification.ERROR

  _onConnectSuccess: (params) =>
    @connected params.access_token, params

  _onConnectError: (error) =>
    @error error

  _onMeSuccess: (data) =>
    @user = data
    @lookupReading()

  _onMeError: () =>
    @error "Unable to fetch user info from Readmill"

  _onBookSuccess: (book) =>
    jQuery.extend @book, book

  _onBookError: =>
    @error "Unable to fetch book info from Readmill"

  _onCreateReadingSuccess: (body, status, jqXHR) =>
    {location} = JSON.parse jqXHR.responseText

    if location
      request = @client.request(url: location, type: "GET")
      request.then @_onGetReadingSuccess, @_onGetReadingError
    else
      @_onGetReadingError()

  _onCreateReadingError: (jqXHR) =>
    @_onCreateReadingSuccess(null, null, jqXHR) if jqXHR.status == 409

  _onGetReadingSuccess: (reading) =>
    @book.reading = reading

  _onGetReadingError: (reading) =>
    @error "Unable to create reading for this book"

  _onAnnotationCreated: (annotation) =>
    if @client.isAuthorized() and @book.id
      @client.createHighlight()
    else
      @unsaved.push annotation
      @connect() unless @client.isAuthorized()

  _onAnnotationUpdated: (annotation) =>

  _onAnnotationDeleted: (annotation) =>
    

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

class View extends Annotator.Plugin
  events:
    ".annotator-readmill-connect a click": "_onConnectClick"
    ".annotator-readmill-logout a click":  "_onLogoutClick"

  classes:
    loggedIn: "annotator-readmill-logged-in"

  template: """
  <div class="annotator-readmill">
    <a class="annotator-readmill-avatar" href="" target="_blank">
      <img src="" />
    </a>
    <div class="annotator-readmill-user">
      <span class="annotator-readmill-fullname"></span>
      <span class="annotator-readmill-username"></span>
    </div>
    <div class="annotator-readmill-book"></div>
    <div class="annotator-readmill-connect">
      <a href="#">Connect with Readmill</a>
    </div>
    <div class="annotator-readmill-logout">
      <a href="#">Log Out</a>
    </div>
  </div>
  """

  constructor: () ->
    super jQuery(@template)

  connect: ->
    this.publish "connect", this

  login: (user) ->
    @updateUser(user) if user
    @element.addClass @classes.loggedIn
    this

  logout: ->
    newElement = jQuery(@template)

    @element.replaceWith newElement
    @element = newElement

    @user = null
    @updateBook @book

    this.publish "disconnect", this

  updateUser: (@user=@user) ->
    if @user
      @element.find(".annotator-readmill-fullname").escape(@user.fullname)
      @element.find(".annotator-readmill-username").escape(@user.username)
      @element.find(".annotator-readmill-avatar").attr("href", @user.permalink_url)
              .find("img").attr("src", @user.avatar_url)
    this

  updateBook: (@book=@book) ->
    if @book
      @element.find(".annotator-readmill-book").escape(@book.title or "Loading book…")
    this

  render: ->
    @updateBook()
    @updateUser()
    @element

  _onConnectClick: (event) =>
    event.preventDefault()
    this.connect()

  _onLogoutClick: (event) =>
    event.preventDefault()
    this.logout()

class Client
  @API_ENDPOINT: "https://api.readmill.com"

  @READING_STATE_INTERESTING: 1
  @READING_STATE_OPEN: 2,
  @READING_STATE_FINISHED: 3
  @READING_STATE_ABANDONED: 4

  constructor: (options) ->
    {@clientId, @accessToken, @apiEndpoint} = options
    @apiEndpoint = Client.API_ENDPOINT unless @apiEndpoint

  me: ->
    @request url: "/me", type: "GET"

  getBook: (bookId) ->
    @request url: "/books/#{bookId}", type: "GET"

  matchBook: (data) ->
    @request url: "/books/match", type: "GET", data: {q: data}

  createBook: (data) ->
    @request url: "/books", type: "POST", data: {book: data}

  createReadingForBook: (bookId, data) ->
    @request type: "POST", url: "/books/#{bookId}/readings", data: {reading: data}

  getHighlights: (url) ->
    @request url: url, type: "GET"

  createHighlight: ->
    @request type: "POST"

  updateHighlight: ->

  deleteHighlight: ->

  request: (options={}) ->
    xhr = null

    if options.url.indexOf("http") != 0
      options.url = "#{@apiEndpoint}#{options.url}"

    if options.type.toUpperCase() of {"POST", "PUT", "DELETE"}
      options.url = "#{options.url}?&client_id=#{@clientId}"
      options.data = JSON.stringify(options.data) if options.data
      options.dataType = "json"
      options.contentType = "application/json"
    else
      options.data = jQuery.extend {client_id: @clientId}, options.data or {}

    options.beforeSend = (jqXHR) =>
      # Set the X-Response header to return the Location header in the body.
      jqXHR.setRequestHeader "X-Response", "Body"
      jqXHR.setRequestHeader "Accept", "application/json"
      jqXHR.setRequestHeader "Authorization", "OAuth #{@accessToken}" if @accessToken

    # jQuery's getResponseHeader() method is broken in Firefox when it comes
    # to accessing CORS headers as it uses the getAllResponseHeaders method
    # which returns an empty string. So here we provide our own xhr factory to
    # the jQuery settings and keep a reference to the original XHR object
    # we then monkey patch the getResponseHeader() to use the native one.
    # See: http://bugs.jquery.com/ticket/10338
    options.xhr = -> xhr = jQuery.ajaxSettings.xhr()

    request = jQuery.ajax options
    request.xhr = xhr
    request.getResponseHeader = (header) -> xhr.getResponseHeader(header)
    request

  authorize: (@accessToken) ->

  isAuthorized: -> !!@accessToken

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
  View: View, Auth: Auth, Store: Store, Client: Client, utils: utils
