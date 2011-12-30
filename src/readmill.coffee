jQuery = Annotator.$

# Grab the Delegator class here as it's useful for other Classes.
Annotator.Class = Annotator.__super__

Annotator.Readmill = class Readmill extends Annotator.Plugin
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
    @view.subscribe "disconnect", @disconnect

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

  disconnect: =>
    @client.deauthorize()
    @store.remove "access-token"
    @annotator.element.find(".annotator-hl").each ->
      jQuery(this).replaceWith this.childNodes

  error: (message) ->
    Annotator.showNotification message, Annotator.Notification.ERROR

  _highlightFromAnnotation: (annotation) ->
    # See: https://github.com/Readmill/API/wiki/Readings
    {
      pre: JSON.stringify(annotation.ranges)
      content: annotation.quote
      highlighted_at: undefined
    }

  _commentFromAnnotation: (annotation) ->
    # Documentation seems to indicate this should be wrapped in an object
    # with a "content" property but that does not seem to work with the
    # POST /highlights API.
    # See: https://github.com/Readmill/API/wiki/Readings
    {content: annotation.text}

  _annotationFromHighlight: (highlight) ->
    ranges = try JSON.parse(highlight.pre) catch e then null

    if ranges
      deferred = new jQuery.Deferred()
      deferred.annotation = annotation =
        quote: highlight.content
        text: ""
        ranges: ranges
        highlightUrl: highlight.uri
        commentUrl: ""
        commentsUrl: highlight.comments

      @client.request(url: highlight.comments).error(deferred.reject).done (comments) ->
        if comments.length
          annotation.text = comments[0].content
          annotation.commentUrl = comments[0].uri
        deferred.resolve annotation

      deferred.promise()
    else
      null

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
    request = @client.getHighlights(reading.highlights)
    request.then @_onGetHighlightsSuccess, @_onGetHighlightsError

  _onGetReadingError: (reading) =>
    @error "Unable to create reading for this book"

  _onGetHighlightsSuccess: (highlights) =>
    deferreds = jQuery.map highlights, jQuery.proxy(this, "_annotationFromHighlight")

    # Filter out unparsable annotations.
    deferreds = jQuery.grep deferreds, (def) -> !!def
    jQuery.when.apply(jQuery, deferreds).done =>
      annotations = jQuery.makeArray(arguments)
      @annotator.loadAnnotations annotations

  _onGetHighlightsError: => @error "Unable to fetch highlights for reading"

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

  _onAnnotationCreated: (annotation) =>
    if @client.isAuthorized() and @book.id
      url = @book.reading.highlights

      # Need a text string here rather than an object here for some reason.
      comment = @_commentFromAnnotation(annotation).content
      highlight = @_highlightFromAnnotation annotation

      request = @client.createHighlight url, highlight, comment
      request.then jQuery.proxy(this, "_onCreateHighlight", annotation), =>
        @error "Unable to send annotation to Readmill"
    else
      @unsaved.push annotation
      @connect() unless @client.isAuthorized()

  _onAnnotationUpdated: (annotation) =>
    data = @_commentFromAnnotation annotation
    if annotation.commentUrl
      request = @client.updateComment annotation.commentUrl, data
    else if annotation.commentsUrl
      request = @client.createComment annotation.commentsUrl, data
      request.done (data) =>
        annotation.commentUrl = data.location

    request.fail((xhr) => @error "Unable to update annotation in Readmill") if request

  _onAnnotationDeleted: (annotation) =>
    if annotation.highlightUrl
      @client.deleteHighlight(annotation.highlightUrl).error =>
        @error "Unable to update annotation in Readmill"
