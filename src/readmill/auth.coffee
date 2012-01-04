# Public: Class for authenticating with Readmill using the implicit OAuth API.
# This essentially opens a new window where the user can grant the plugin
# access to thier account. The window is then redirected back to callback.html
# which calls Annotator.Readmill.Auth.callback() and the access token is
# extracted from the hash fragment in the url.
#
# Examples
#
#   auth = new Auth
#     clientID: "12345"
#     callbackUri: "http://example.com/callback.html"
#   auth.connect().done (params) ->
#     # Params are extracted from the popup hash.
#     user.token = params.access_token
#
# Returns a new instance of Auth.
Annotator.Readmill.Auth = class Auth
  # Export private variables local to this class.
  utils  = Annotator.Readmill.utils
  jQuery = Annotator.$

  # Public: Default endpoint for the authorisation. Can be overrided by
  # passing @authEndpoint property in to the constructor.
  @AUTH_ENDPOINT: "https://readmill.com/oauth/authorize"

  # Public: Generates a unique id for the auth request. Useful for the "state"
  # property to prevent CSRF.
  #
  # Examples
  #
  #   Auth.uuid() #=> "state-1"
  #   Auth.uuid() #=> "state-2"
  #
  # Returns a string unique to this browser window.
  @uuid: ->
    Auth.uuid.counter = 0 unless Auth.uuid.counter
    "state-#{Auth.uuid.counter += 1}"

  # Sets up the instance properties for the class.
  #
  # options - Setup options for the class (default: {}).
  #           clientID     - Client ID for the plugin.
  #           callbackUri  - Full url of the callback html file.
  #           authEndpoint - Alternative auth endpoint (optional).
  #
  # Returns nothing.
  constructor: (options) ->
    {@clientId, @callbackUri, @authEndpoint} = options
    unless @clientId
      throw new Error '"clientId" option is required by Readmill.Auth'
    unless @callbackUri
      throw new Error '"callbackUri" option is required by Readmill.Auth'

    @authEndpoint = Auth.AUTH_ENDPOINT unless @authEndpoint

  # Public: Begin the OAuth authentication by opening a popup window for the
  # user to sign in. Returns an instance of jQuery.Deferred which has the
  # #done() and #fail() methods through which callbacks can be registered.
  #
  # done() callbacks recieve an object of parameters extracted from the hash.
  # This includes the "access_token" property. fail() callbacks recieve the
  # error string from the hash.
  #
  # Examples
  #
  #   request = auth.connect()
  #   request.done (params) -> console.log(params.auth_token)
  #   request.fail (error)  -> console.log(error)
  #
  # Returns an instance of jQuery.Deferred().
  connect: ->
    deferred = new jQuery.Deferred()
    deferred.id = Auth.uuid()

    params =
      response_type: "code"
      client_id: @clientId
      redirect_uri: @callbackUri
      state: deferred.id
    qs = utils.serializeQueryString(params)

    Auth.callback = jQuery.proxy(@callback, this, deferred)

    @popup = @openWindow "#{@authEndpoint}?#{qs}"
    deferred.promise()

  # Internal: Callback called when the authentication cycle completes. This
  # should be called in the callback.html file and will trigger the appropriate
  # #resolve()/#reject() method on the deferred argument.
  #
  # This method is not called directly but instead used by #connect() to
  # create a global callback handler.
  #
  # deferred - An instance of jQuery.deferred() to resolve.
  #
  # Examples
  #
  #   auth.connect() #=> Creates Auth.callback()
  #   Auth.callback()
  #
  # Returns nothing.
  callback: (deferred) ->
    hash = @popup.location.hash.slice(1)
    params = qs = utils.parseQueryString(hash)
    @popup.close()

    if params.access_token# and params.state is @deferred.id
      deferred.resolve params
    else
      deferred.reject params.error# or "bad-state"

  # Internal: Opens an new popup window and retains a reference to it in
  # the @popup property.
  #
  # url    - The url of the window to open.
  # width  - The window width (default: 725).
  # height - The window height (default: 575).
  #
  # Examples
  #
  #   win = auth.openWindow("http://example.com", 640, 480)
  #   win.location.hash
  #
  # Returns a Window instance.
  openWindow: (url, width=725, height=575) ->
    left = window.screenX + (window.outerWidth  - width)  / 2
    top  = window.screenY + (window.outerHeight - height) / 2

    params =
      toolbar: no, location: 1, scrollbars: yes
      top: top, left: left, width:  width, height: height

    paramString = utils.serializeQueryString(params, ",")
    window.open url, "readmill-connect", paramString
