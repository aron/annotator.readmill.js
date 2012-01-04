jQuery = Annotator.$

# Grab the Delegator class here as it's useful for other Classes.
Annotator.Class = Annotator.__super__.constructor

# Base class for the Readmill plugin. This will be called via the jQuery 
# annotator interface.
#
# The "book", "clientId" and "callbackUri" arguments are required. The
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
#           callbackUri: "http://example.com/callback.html"
#         });
#
# Returns a new instance of Readmill.
Annotator.Readmill = class Readmill extends Annotator.Plugin
  # DOM and custom event to callback map.
  events:
    "annotationCreated": "_onAnnotationCreated"
    "annotationUpdated": "_onAnnotationUpdated"
    "annotationDeleted": "_onAnnotationDeleted"

  # Initialises the plugin instance and sets up properties.
  #
  # element - The root Annotator element.
  # options - An object literal of options.
  #           book        - An object of book metadata.
  #           clientId    - The client id string for the service.
  #           callbackUri - A full url pointing to the callback.html file.
  #           accessToken - A pre activated accessToken (optional).
  #
  # Returns nothing.
  # Raises an Error if any of the required arguments are missing.
  constructor: (element, options) ->
    super

    # Rather than use CoffeeScript's scope binding for all the event handlers 
    # in this class (which generates a line of JavaScript per binding) we use a
    # utilty function to manually bind all functions beginning with "_on" to
    # the current scope.
    Readmill.utils.proxyHandlers this

    # Ensure required options are provided.
    errors = (key for own key in ["book", "clientId", "callbackUri"] when not options[key])
    if errors.length
      throw new Error """
        options "#{errors.join('", ')}" are required by the Readmill plugin. eg:

        jQuery("#content").annotator()
        .annotator("addPlugin", "Readmill", {
          book: {id: "52"}, /* Or use a title & author. */
          book: {title: "Brighton Rock", author: "Graham Greene"}
          clientId: "12345",
          callbackUri: "http://example.com/callback.html"
        });
      """

    @user   = null
    @book   = @options.book
    @view   = new Readmill.View
    @auth   = new Readmill.Auth @options
    @store  = new Readmill.Store
    @client = new Readmill.Client @options

    @view.subscribe "connect", @connect
    @view.subscribe "disconnect", @disconnect

    token = options.accessToken or @store.get "access-token"
    @connected(token, silent: true) if token
    @unsaved = []

  # Internal: Called by the Annotator after the intance has been created and 
  # @annotator property has been attached. Sets up initial plugin state.
  #
  # Returns nothing.
  pluginInit: ->
    jQuery("body").append @view.render()
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

  disconnect: =>
    @client.deauthorize()
    @store.remove "access-token"
    @annotator.element.find(".annotator-hl").each ->
      jQuery(this).replaceWith this.childNodes

  error: (message) ->
    Annotator.showNotification message, Annotator.Notification.ERROR

  _onConnectSuccess: (params) ->
    @connected params.access_token, params

  _onConnectError: (error) ->
    @error error

  _onMeSuccess: (data) ->
    @user = data
    @lookupReading()

  _onMeError: () ->
    @error "Unable to fetch user info from Readmill"

  _onBookSuccess: (book) ->
    jQuery.extend @book, book

  _onBookError: ->
    @error "Unable to fetch book info from Readmill"

  _onCreateReadingSuccess: (body, status, jqXHR) ->
    {location} = JSON.parse jqXHR.responseText

    if location
      request = @client.request(url: location, type: "GET")
      request.then @_onGetReadingSuccess, @_onGetReadingError
    else
      @_onGetReadingError()

  _onCreateReadingError: (jqXHR) ->
    @_onCreateReadingSuccess(null, null, jqXHR) if jqXHR.status == 409

  _onGetReadingSuccess: (reading) ->
    @book.reading = reading
    request = @client.getHighlights(reading.highlights)
    request.then @_onGetHighlightsSuccess, @_onGetHighlightsError

  _onGetReadingError: (reading) ->
    @error "Unable to create reading for this book"

  _onGetHighlightsSuccess: (highlights) ->
    promises = jQuery.map highlights, (highlight) =>
      Readmill.utils.annotationFromHighlight(highlight, @client)

    # Filter out unparsable annotations.
    promises = jQuery.grep deferreds, (prom) -> prom.state() isnt "rejected"
    jQuery.when.apply(jQuery, promises).done =>
      annotations = jQuery.makeArray(arguments)
      @annotator.loadAnnotations annotations

  _onGetHighlightsError: -> @error "Unable to fetch highlights for reading"

  _onCreateHighlight: (annotation, data) ->
    # Now try and get a permalink for the comment by fetching the first
    # comment for the newly created highlight.
    @client.request(url: data.location).done (highlight) =>
      # Need to store this rather than data.location in order to be able to
      # delete the highlight at a later date.
      annotation.highlightUrl = highlight.uri
      annotation.commentsUrl = highlight.comments
      @client.request(url: highlight.comments).done (comments) ->
        annotation.commentUrl = comments[0].uri if comments.length

  _onAnnotationCreated: (annotation) ->
    if @client.isAuthorized() and @book.id
      url = @book.reading.highlights
      utils = Readmill.utils

      # Need a text string here rather than an object here for some reason.
      comment   = utils.commentFromAnnotation(annotation).content
      highlight = utils.highlightFromAnnotation annotation

      request = @client.createHighlight url, highlight, comment
      request.then jQuery.proxy(this, "_onCreateHighlight", annotation), =>
        @error "Unable to send annotation to Readmill"
    else
      @unsaved.push annotation
      @connect() unless @client.isAuthorized()

  _onAnnotationUpdated: (annotation) ->
    data = Readmill.utils.commentFromAnnotation annotation
    if annotation.commentUrl
      request = @client.updateComment annotation.commentUrl, data
    else if annotation.commentsUrl
      request = @client.createComment annotation.commentsUrl, data
      request.done (data) =>
        annotation.commentUrl = data.location

    request.fail((xhr) => @error "Unable to update annotation in Readmill") if request

  _onAnnotationDeleted: (annotation) ->
    if annotation.highlightUrl
      @client.deleteHighlight(annotation.highlightUrl).error =>
        @error "Unable to update annotation in Readmill"

window.Annotator.Plugin.Readmill = Annotator.Readmill
