# Base class for the Readmill plugin. This will be called via the jQuery
# annotator interface.
#
# The "book", "clientId" and "callbackUrl" arguments are required. The
# book should be an object literal for a book on Readmill ideally with an
# "id" but if only a "title", "author" are provided the plugin will
# create the book for you.
#
# Examples
#
#   jQuery("#content").annotator()
#         .annotator("addPlugin", "Readmill", {
#           book: {id: 52},
#           clientId: "123456",
#           callbackUrl: "http://example.com/callback.html"
#         });
#
# Returns a new instance of Readmill.
Annotator.Readmill = class Readmill extends Annotator.Plugin
  # Privately export jQuery variable local only to this class.
  jQuery = Annotator.$

  # DOM and custom event to callback map.
  events:
    "annotationCreated": "_onAnnotationCreated"
    "annotationUpdated": "_onAnnotationUpdated"
    "annotationDeleted": "_onAnnotationDeleted"

  # Default options for the class.
  options:
    # Gets a unique identifier for this page. This allows a book to be spread
    # over multiple html pages but retain a single resource on Readmill. By
    # default this is the page URI up to the query string.
    #
    # Returns a unique id for the page.
    getPage: -> window.location.href.split('?').shift()

  # Initialises the plugin instance and sets up properties.
  #
  # element - The root Annotator element.
  # options - An object literal of options.
  #           book        - An object of book metadata.
  #           clientId    - The client id string for the service.
  #           callbackUrl - A full url pointing to the callback.html file.
  #           accessToken - A pre activated accessToken (optional).
  #           getPage     - A function that returns a page id (optional).
  #
  # Returns nothing.
  # Raises an Error if any of the required arguments are missing.
  constructor: (element, options) ->
    super

    # Ensure required options are provided.
    errors = (key for own key in ["book", "clientId", "callbackUrl"] when not options[key])
    if errors.length
      throw new Error """
        options "#{errors.join('", ')}" are required by the Readmill plugin. eg:

        jQuery("#content").annotator()
        .annotator("addPlugin", "Readmill", {
          book: {id: "52"}, /* Or use a title & author. */
          book: {title: "Brighton Rock", author: "Graham Greene"}
          clientId: "12345",
          callbackUrl: "http://example.com/callback.html"
        });
      """

    @user   = null
    @book   = @options.book
    @view   = new Readmill.View
    @auth   = new Readmill.Auth @options
    @store  = new Readmill.Store
    @client = new Readmill.Client @options

    # Rather than use CoffeeScript's scope binding for all the event handlers
    # in this class (which generates a line of JavaScript per binding) we use a
    # utilty function to manually bind all functions beginning with "_on" to
    # the current scope.
    Readmill.utils.proxyHandlers this

    # Decorate all error handlers with a callback to check for unauthorised
    # responses.
    for own key, value of this when key.indexOf("Error") > -1
      this[key] = @_createUnauthorizedHandler(value)

    token = options.accessToken or @store.get("access-token")
    @connected(token, silent: true) if token
    @unsaved = []

  # Internal: Called by the Annotator after the intance has been created and
  # @annotator property has been attached. Sets up initial plugin state.
  #
  # Returns nothing.
  pluginInit: ->
    @view.on "reading",    @lookupReading
    @view.on "finish",     @endReading
    @view.on "privacy",    @updatePrivacy
    @view.on "connect",    @connect
    @view.on "disconnect", @disconnect

    jQuery("body").append @view.render()

    if @client.isAuthorized()
      @lookupReading().done => @view.reading()
    else
      @lookupBook()

  # Public: Fetches the book resource from the Readmill API and updates the
  # view when complete. This method is usually called as part of the plugin
  # setup.
  #
  # The method also attaches a "promise" property to @book which can be used
  # to determine if the book is loaded.
  #
  # Examples
  #
  #   readmill.lookupBook()
  #
  # Returns a jQuery.Deferred() promise.
  lookupBook: ->
    return @book.promise if @book.promise

    @book.promise = if @book.id
      @client.getBook @book.id
    else
      @client.matchBook @book

    @book.promise.then(@_onBookSuccess, @_onBookError).done =>
      @view.updateBook @book

  # Public: Queries/Creates a reading for the current book.
  #
  # Examples
  #
  #   request = readmill.lookupReading()
  #   request.done -> console.log request.reading.id
  #
  # Returns a jQuery.Deferred() promise.
  lookupReading: =>
    @lookupBook().done =>
      request = @client.createReadingForBook @book.id,
        state: Readmill.Client.READING_STATE_OPEN
        private: @view.isPrivate()
      request.then(@_onCreateReadingSuccess, @_onCreateReadingError)

  # Public: Ends the current reading session if one exists by marking
  # the book as finished.
  #
  # Examples
  #
  #   readmill.endReading()
  #
  # Returns a jQuery.Deferred() promise.
  endReading: =>
    if @book.reading
      @client.updateReading @book.reading.uri,
        state: Readmill.Client.READING_STATE_FINISHED
      @removeAnnotations()
      delete @book.reading

  # Public: Updates the privacy of the reading depending on the status
  # of the view.
  #
  # Returns jQuery.Deferred promise.
  updatePrivacy: =>
    isPrivate = @view.isPrivate()
    if @book.reading and @book.reading.private isnt isPrivate
      @book.reading.private = isPrivate
      request = @client.updateReading(@book.reading.uri, private: isPrivate)
      request.fail(@_onUpdatePrivacyError)

  # Public: Begins the Readmill authentication flow.
  #
  # Examples
  #
  #   auth = readmill.connect()
  #   auth.done -> readmill.client.me() # Load the user data.
  #
  # Returns a jQuery.Deferred() promise.
  connect: =>
    @auth.connect().then @_onConnectSuccess, @_onConnectError

  # Public: Setup method that should be called once the user is authenticated
  # with Readmill. Will display a notification unless options.silent argument
  # is provided.
  #
  # accessToken - Access token for the client/current user.
  # options     - An object of method options (default: {}).
  #               silent: If true will not display the notification.
  #
  # Examples
  #
  #   readmill.connected("abcdefgh")
  #   readmill.connected("abcdefgh", silent: true)
  #
  # Returns nothing.
  connected: (accessToken, options={}) ->
    @client.authorize accessToken
    @client.me().then(@_onMeSuccess, @_onMeError).done =>
      @view.login @user

    @store.set "access-token", accessToken, options.expires

    unless options?.silent is true
      Annotator.showNotification "Successfully connected to Readmill"

  # Public: Displays an unauthorized notification. Should be called when
  # a user is required to reconnect with Readmill.
  #
  # Examples
  #
  #   readmill.unauthorized()
  #
  # Returns nothing.
  unauthorized: ->
    msg = "Not connected to Readmill, click here to connect"
    Annotator.showNotification(msg)
    @disconnect(removeAnnotations: false)

    # Watch for the users clicks on the notifiaction banner.
    notification = jQuery(".annotator-notice").one "click.readmill-auth", =>
      @connect()
    # Unbind the event listener manually after five seconds.
    unbind = => notification.unbind(".readmill-auth")
    setTimeout(unbind, 5000)

  # Public: Removes all traces of the user from the plugin.
  #
  # 1. Deauthorises the client instance.
  # 2. Removes related local storage entries.
  # 3. Removes annotations from the document.
  #
  # Examples
  #
  #   jQuery("#logout").click -> readmill.disconnect()
  #
  # Returns nothing.
  disconnect: (options={}) =>
    @client.deauthorize()
    @store.remove("access-token")
    @removeAnnotations() unless options.removeAnnotations is false

  # Internal: Helper method for displaying error notifications.
  #
  # message - Message to display to the user.
  #
  # Examples
  #
  #   readmill.error("Unable to find this book")
  #
  # Returns nothing.
  error: (message) ->
    Annotator.showNotification message, Annotator.Notification.ERROR

  # Internal: Removes all annotations from the current page.
  #
  # Examples
  #
  #   readmill.removeAnnotations()
  #
  # Returns nothing.
  removeAnnotations: ->
    @element.find(".annotator-hl").each ->
      jQuery(this).replaceWith this.childNodes

  # Decorator method for error callbacks for client requests. Returns a wrapped
  # function which handles 401 Unauthorized responses and requests the user to
  # reconnect with Readmill.
  #
  # wrapped - The error handler to wrap.
  #
  # Examples
  #
  #   handler = readmill._createUnauthorizedHandler (jqXHR) ->
  #     console.log "An error has occured."
  #   readmill.me().error(handler)
  #
  # Returns a new callback function.
  _createUnauthorizedHandler: (handler) ->
    (jqXHR) =>
      isUnauthorized = jqXHR and (jqXHR.status is 401 or jqXHR.status is 0)
      if isUnauthorized then @unauthorized() else handler.apply(this, arguments)

  _onConnectSuccess: (params) ->
    @connected params.access_token, params

  _onConnectError: (error) ->
    @error error

  _onMeSuccess: (data) ->
    @user = data

  _onMeError: () ->
    @error "Unable to fetch user info from Readmill"

  _onBookSuccess: (book) ->
    jQuery.extend @book, book

  _onBookError: ->
    @error "Unable to fetch book info from Readmill"

  _onCreateReadingSuccess: (body, status, jqXHR) ->
    {location} = body
    if location
      request = @client.request(url: location)
      request.then @_onGetReadingSuccess, @_onGetReadingError
    else
      @_onGetReadingError()

  _onCreateReadingError: (jqXHR) ->
    if jqXHR.status == 409
      body = JSON.parse jqXHR.responseText
      @_onCreateReadingSuccess(body, "success", jqXHR)
    else
      @error "Unable to create a reading for this book"

  # Public: Callback handler for failiure to update the privacy value.
  #
  # jqXHR - The jqXHR object for the failed request.
  #
  # Returns nothing.
  _onUpdatePrivacyError: (jqXHR) ->
    @error "Unable to update the privacy state for this book"

  _onGetReadingSuccess: (reading) ->
    @book.reading = reading
    @view.updateBook(@book)
    request = @client.getHighlights(reading.highlights)
    request.then @_onGetHighlightsSuccess, @_onGetHighlightsError

  _onGetReadingError: () ->
    @error "Unable to create a reading for this book"

  _onGetHighlightsSuccess: (highlights) ->
    promises = jQuery.map highlights, (highlight) =>
      Readmill.utils.annotationFromHighlight(highlight, @client)

    # Filter out unparsable annotations.
    promises = jQuery.grep promises, (prom) -> prom.state() isnt "rejected"
    jQuery.when.apply(jQuery, promises).done =>
      annotations = jQuery.makeArray(arguments)
      @annotator.loadAnnotations annotations

  _onGetHighlightsError: ->
    @error "Unable to fetch highlights for reading"

  _onCreateHighlight: (annotation, data) ->
    # Now fetch the highlight resource in order to get the required
    # urls for the highlight, comments and comment resources.
    @client.request(url: data.location).done (highlight) =>
      # Need to store this rather than data.location in order to be able to
      # delete the highlight at a later date.
      annotation.id = highlight.id
      annotation.highlightUrl = highlight.uri
      annotation.commentsUrl  = highlight.comments

      # Now create the comment for the highlight. We can do this using the
      # @_onAnnotationUpdated() method which does this anyway. This should
      # probably be moved out the callback methods in a later refactor.
      @_onAnnotationUpdated(annotation) if annotation.text

  _onBeforeAnnotationCreated: (annotation) ->
    annotation.page = @options.getPage()

  _onAnnotationCreated: (annotation) ->
    if @client.isAuthorized() and @book.id and @book.reading?.highlights
      url = @book.reading.highlights
      highlight = Readmill.utils.highlightFromAnnotation annotation

      # We don't create the comment here as we can't easily access the url
      # permalink. The comment is instead created in the success callback.
      request = @client.createHighlight url, highlight
      request.done jQuery.proxy(this, "_onCreateHighlight", annotation)
      request.fail @_onAnnotationCreatedError
    else
      @unsaved.push annotation
      @unauthorized() unless @client.isAuthorized()
      unless @book.id
        @lookupBook().done => @_onAnnotationCreated(annotation)

  _onAnnotationCreatedError: ->
    @error "Unable to save annotation to Readmill"

  _onAnnotationUpdated: (annotation) ->
    data = Readmill.utils.commentFromAnnotation annotation
    if annotation.commentUrl
      request = @client.updateComment annotation.commentUrl, data
    else if annotation.commentsUrl
      request = @client.createComment annotation.commentsUrl, data
      request.done (data) =>
        annotation.commentUrl = data.location
    request.fail @_onAnnotationUpdatedError if request

  _onAnnotationUpdatedError: ->
    @error "Unable to update annotation in Readmill"

  _onAnnotationDeleted: (annotation) ->
    if annotation.highlightUrl
      request = @client.deleteHighlight(annotation.highlightUrl)
      request.fail @_onAnnotationDeletedError

  _onAnnotationDeletedError: ->
     @error "Unable to delete annotation on Readmill"

# Grab the Delegator class here as it's useful for other Classes.
Annotator.Class = Annotator.__super__.constructor
Annotator.Plugin.Readmill = Annotator.Readmill
