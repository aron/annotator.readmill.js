# Client class for interacting with the Readmill API. Manages the Auth headers
# and client_id parameters. Also provides helper methods for common API
# requests.
#
# Examples
#
#   client = new Client clientId: "12345", accessToken: "abcdefg"
#   request = client.getBook 123
#   request.done (book) -> console.log "Retrieved #{book.title}"
#
# Returns a new instance of Client.
Annotator.Readmill.Client = class Client
  # Export jQuery into local scope.
  jQuery = Annotator.$

  # Public: Default endpoint for the API. Can be overridden by passing an
  # "apiEndpoint" property in the constructor options.
  @API_ENDPOINT: "https://api.readmill.com"

  # Public: Reading states.
  @READING_STATE_INTERESTING: 1
  @READING_STATE_OPEN:        2
  @READING_STATE_FINISHED:    3
  @READING_STATE_ABANDONED:   4

  # Public: Sets up the instance properties and checks for presence of
  # required options.
  #
  # options - An object of initilaisation options.
  #           clientId:    The client id for the plugin.
  #           accessToken: A previously authenticated access token,
  #                        required to make some requests (optional).
  #           apiEndpoint: An alternative API endpoint (optional).
  #
  # Returns nothing.
  # Raises Error if options.clientId is not provided.
  constructor: (options={}) ->
    {@clientId, @accessToken, @apiEndpoint} = options
    throw new Error "test" unless @clientId
    @apiEndpoint = Client.API_ENDPOINT unless @apiEndpoint

  # Public: Gets the data for the current user.
  #
  # Returns a jQuery.Deferred() promise.
  me: ->
    debugger
    @request url: "/me", type: "GET"

  # Public: Gets data for the book id provided. If no id is known then use
  # @matchBook() to get the best match.
  #
  # bookId - The id string for the book to lookup.
  #
  # Returns a jQuery.Deferred() promise.
  getBook: (bookId) ->
    @request url: "/books/#{bookId}", type: "GET"

  # Public: Finds the closest match for book details provided. If the book
  # id is known then @getBook() should be used instead.
  #
  # data - Query data to add to the query string.
  #        title  - The book title (optional).
  #        author - The book author (optional).
  #        isbn   - The book isbn (optional).
  #
  # Returns a jQuery.Deferred() promise.
  matchBook: (data) ->
    @request url: "/books/match", type: "GET", data: {q: data}

  # Public: Creates a new book with the data provided.
  #
  # book - Object literal of book data.
  #        title  - The book title.
  #        author - The book author.
  #        isbn   - The book isbn (optional).
  #
  # Returns a jQuery.Deferred() promise.
  createBook: (book) ->
    @request url: "/books", type: "POST", data: {book}

  # Public: Attempts to create a reading for a book. If a reading already exists
  # the promise.fail() method will be called and the response status will be
  # 409. If this is the case then the "location" property should be extracted
  # from the Location header or the JSON body and requested.
  #
  # bookId  - The id of the book to create a reading for.
  # reading - Object literal of reading options.
  #
  # Returns a jQuery.Deferred() promise.
  createReadingForBook: (bookId, reading) ->
    @request type: "POST", url: "/books/#{bookId}/readings", data: {reading}

  # Public: Gets an array of highlight objects for the reading. The url can
  # be extracted from the "highlights" property of a reading.
  #
  # url - Highlight url for the reading.
  #
  # Returns a jQuery.Deferred() promise.
  getHighlights: (url) ->
    @request url: url, type: "GET"

  # Public: Gets a single highlight object for the reading. The url can
  # be extracted from the @getHighlights() array or a newly created highlight.
  #
  # url - Highlight url for the reading.
  #
  # Returns a jQuery.Deferred() promise.
  getHighlight: (url) ->
    @request url: url, type: "GET"

  # Public: Creates a new highlight for a reading. An optional comment can be
  # provided although there is no direct way to obtain the permalink
  # for the created resource to update it. So it may be better to create the
  # comment in a second request.
  #
  # url       - Url for the reading highlights.
  # highlight - Highlight data object.
  # comment   - Comment string (default: null)
  #
  # Returns a jQuery.Deferred() promise.
  createHighlight: (url, highlight, comment) ->
    @request type: "POST", url: url, data: {highlight, comment}

  # Public: Deletes a highlight at the url provided.
  #
  # url - A highlight url.
  #
  # Returns a jQuery.Deferred() promise.
  deleteHighlight: (url) ->
    @request type: "DELETE", url: url

  # Public: Creates a comment at the url provided. The url can either be a
  # comment for a reading or a highlight.
  #
  # url     - A highlight url.
  # comment - A comment data object.
  #
  # Returns a jQuery.Deferred() promise.
  createComment: (url, comment) ->
    @request type: "POST", url: url, data: {comment}

  # Public: Updates a comment at the url provided. The url can either be a
  # comment for a reading or a highlight.
  #
  # url     - A highlight url.
  # comment - A comment data object.
  #
  # Returns a jQuery.Deferred() promise.
  updateComment: (url, comment) ->
    @request type: "PUT", url: url, data: {comment}

  # Public: Makes a generic request to the API server. Requires a "url" option
  # and returns a jQuery deferred object onto which "done" and "fail" callbacks
  # can be registered.
  #
  # The method accepts any options that can be passed into jQuery.ajax().
  #
  # options - An object of request options.
  #           url: The url to request, accepts just the path (required).
  #
  # Examples
  #
  #   request = @request url: "/me", type: "GET"
  #   request.done (response) -> console.log(response)
  #
  # Returns a jQuery.Deferred() promise instance.
  request: (options={}) ->
    xhr = null

    options.type = "GET" unless options.type

    if options.url.indexOf("http") != 0
      options.url = "#{@apiEndpoint}#{options.url}"

    if options.type.toUpperCase() of {"POST", "PUT", "DELETE"}
      options.url = "#{options.url}?&client_id=#{@clientId}"
      options.data = JSON.stringify(options.data) if options.data
      options.dataType = "json"
      options.contentType = "application/json"
    else
      options.data = jQuery.extend {client_id: @clientId}, options.data or {}

    # Trim whitespace from responses before passing to JSON.parse().
    options.dataFilter = jQuery.trim

    options.beforeSend = (jqXHR) =>
      # Set the X-Response header to return the Location header in the body.
      jqXHR.setRequestHeader "X-Response", "Body"
      jqXHR.setRequestHeader "Accept", "application/json"
      if @accessToken
        jqXHR.setRequestHeader "Authorization", "OAuth #{@accessToken}"

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

  # Public: Sets the accessToken property after the class has been created.
  #
  # accessToken - The accessToken for the current user.
  #
  # Examples
  #
  #   client = new Client clientId: "12345"
  #   auth.connect.done (params) ->
  #     client.authorize(params.access_token)
  #
  # Returns itself.
  authorize: (@accessToken) -> this

  # Public: Deauthorises the accessToken for the client, should be called when
  # the user logs out.
  #
  # Examples
  #
  #   onLogout = -> client.deauthorize()
  #
  # Returns itself.
  deauthorize: -> @accessToken = null; this

  # Public: Checks to see if the client is currently authorized.
  #
  # Examples
  #
  #   request = if client.isAuthorized() then client.me
  #
  # Returns true if the client is authorized.
  isAuthorized: -> !!@accessToken
