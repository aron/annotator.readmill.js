describe "Readmill", ->
  jQuery   = Annotator.$
  Readmill = Annotator.Readmill
  readmill = null

  beforeEach ->
    sinon.stub(Readmill.Store.prototype, "get").returns(null)
    readmill = new Readmill $("<div />"),
      book: {}
      clientId: "12345"
      callbackUrl: "http://localhost/callback.html"

  afterEach ->
    Readmill.Store.prototype.get.restore()

  it "should be an instance of Annotator.Plugin", ->
    expect(readmill).to.be.an.instanceof Annotator.Plugin

  it "should call @connected() with the access token if provided", ->
    sinon.stub(Readmill.prototype, "connected")
    target = new Readmill $("<div />"),
      book: {}
      clientId: "12345"
      accessToken: "abcdefg"
      callbackUrl: "http://localhost/callback.html"
    expect(target.connected).was.called()
    expect(target.connected).was.calledWith("abcdefg")
    Readmill.prototype.connected.restore()

  it "should call @connected() with the access token if in localStorage", ->
    sinon.stub(Readmill.prototype, "connected")
    Readmill.Store.prototype.get.returns("abcdefg")

    target = new Readmill $("<div />"),
      book: {}
      clientId: "12345"
      callbackUrl: "http://localhost/callback.html"
    expect(target.connected).was.called()
    expect(target.connected).was.calledWith("abcdefg")

    Readmill.prototype.connected.restore()

  it "should raise an Error if any required parameters are missing", ->
    target = ->
      target = new Readmill $("<div />"),
        clientId: "12345"
        callbackUrl: "http://localhost/callback.html"
    expect(target).to.throw(Error)

  describe "#pluginInit()", ->
    beforeEach ->
      sinon.stub(jQuery.fn, "append")
      sinon.stub(readmill, "lookupBook")

    afterEach ->
      jQuery.fn.append.restore()

    it "should append the @view.element to the document body", ->
      readmill.pluginInit()
      expect(jQuery.fn.append).was.called()
      expect(jQuery.fn.append).was.calledWith(readmill.view.element)

    it "should call @lookupBook", ->
      readmill.pluginInit()
      expect(readmill.lookupBook).was.called()

    it "should register view event listeners", ->
      target = sinon.stub(readmill.view, "on")
      readmill.pluginInit()
      expect(readmill.view.on).was.calledWith("reading",    readmill.lookupReading)
      expect(readmill.view.on).was.calledWith("connect",    readmill.connect)
      expect(readmill.view.on).was.calledWith("disconnect", readmill.disconnect)

  describe "#lookupBook()", ->
    promise = null

    beforeEach ->
      readmill.book = {id: 1}
      promise = sinon.createPromiseStub()
      sinon.stub(readmill.client, "getBook").returns promise
      sinon.stub(readmill.client, "matchBook").returns promise

    it "should call @client.getBook() if an book.id is provided", ->
      readmill.lookupBook()
      expect(readmill.client.getBook).was.called()
      expect(readmill.client.getBook).was.calledWith(1)

    it "should call @client.matchBook() if no book.id is provided", ->
      readmill.book = author: "Graham Greene", title: "Brighton Rock"
      readmill.lookupBook()
      expect(readmill.client.matchBook).was.called()
      expect(readmill.client.matchBook).was.calledWith(readmill.book)

    it "should return a jQuery.Deferred() promise", ->
      expect(readmill.lookupBook()).to.equal(promise)

    it "should register @_onBookSuccess and @_onBookError callbacks", ->
      readmill.lookupBook()
      expect(promise.then).was.called()
      expect(promise.then).was.calledWith(readmill._onBookSuccess, readmill._onBookError)

    it "should return the book.promise if it already exists", ->
      readmill.book.promise = promise
      expect(readmill.lookupBook()).to.equal(promise)

  describe "#lookupReading()", ->
    bookPromise    = null
    readingPromise = null

    beforeEach ->
      bookPromise    = sinon.createPromiseStub()
      readingPromise = sinon.createPromiseStub()

      sinon.stub(readmill, "lookupBook").returns bookPromise
      sinon.stub(readmill.client, "createReadingForBook").returns readingPromise

    it "should call @lookupBook()", ->
      readmill.lookupReading()
      expect(readmill.lookupBook).was.called()

    it "should call @client.createReadingForBook()", ->
      readmill.lookupReading()
      bookPromise.done.args[0][0]()
      expect(readmill.client.createReadingForBook).was.called()

    it "should register the @_onCreateReadingSuccess and @_onCreateReadingError callbacks", ->
      readmill.lookupReading()
      bookPromise.done.args[0][0]()
      expect(readingPromise.then).was.called()
      expect(readingPromise.then).was.calledWith(readmill._onCreateReadingSuccess, readmill._onCreateReadingError)

  describe "#updatePrivacy()", ->
    it "should update the privacy depending on the view state", ->
      readmill.book.reading = {uri: "http://"}
      sinon.stub(readmill.view, "isPrivate").returns(true)
      sinon.stub(readmill.client, "updateReading")

      readmill.updatePrivacy()
      expect(readmill.view.isPrivate).was.called()
      expect(readmill.client.updateReading).was.called()
      expect(readmill.client.updateReading).was.calledWith("http://", private: true)

    it "should do nothing if there is no reading", ->
      sinon.stub(readmill.client, "updateReading")
      readmill.updatePrivacy()
      expect(readmill.client.updateReading).was.notCalled()

  describe "#connect()", ->
    promise = null

    beforeEach ->
      promise = sinon.createPromiseStub()
      sinon.stub(readmill.auth, "connect").returns(promise)

    it "should call @auth.connect()", ->
      readmill.connect()
      expect(readmill.auth.connect).was.called()

    it "should register the @_onConnectSuccess and @_onConnectError callbacks", ->
      readmill.connect()
      expect(promise.then).was.called()
      expect(promise.then).was.calledWith(readmill._onConnectSuccess, readmill._onConnectError)

  describe "#connected()", ->
    promise = null

    beforeEach ->
      promise = sinon.createPromiseStub()
      sinon.stub(readmill.store, "set")
      sinon.stub(readmill.client, "me").returns(promise)
      sinon.stub(readmill.client, "authorize")
      sinon.stub(Annotator, "showNotification")

    afterEach ->
      Annotator.showNotification.restore()

    it "should authorise the @client", ->
      readmill.connected("123456")
      expect(readmill.client.authorize).was.called()

    it "should request the users details from Readmill", ->
      readmill.connected("123456")
      expect(readmill.client.me).was.called()

    it "should register the @_onMeSuccess and @_onMeError callbacks", ->
      readmill.connected("123456")
      expect(promise.then).was.called()
      expect(promise.then).was.calledWith(readmill._onMeSuccess, readmill._onMeError)

    it "should save the access token in the @store", ->
      readmill.connected("123456")
      expect(readmill.store.set).was.called()
      expect(readmill.store.set).was.calledWith("access-token", "123456")

    it "should save the access token in the @store with an expires time", ->
      readmill.connected("123456", expires: 3000)
      expect(readmill.store.set).was.called()
      expect(readmill.store.set).was.calledWith("access-token", "123456", 3000)

    it "should display a success notification", ->
      readmill.connected("123456")
      expect(Annotator.showNotification).was.called()
      expect(Annotator.showNotification).was.calledWith("Successfully connected to Readmill")

    it "should not display a success notification if options.silent is true", ->
      readmill.connected("123456", silent: true)
      expect(Annotator.showNotification).was.notCalled()

  describe "#disconnect()", ->
    beforeEach ->
      sinon.stub(readmill.store, "remove")
      sinon.stub(readmill.client, "deauthorize")
      sinon.stub(readmill.element, "find").returns
        each: sinon.spy()

    it "should deauthorise the @client", ->
      readmill.disconnect()
      expect(readmill.client.deauthorize).was.called()

    it "should remove the api token from local storage", ->
      readmill.disconnect()
      expect(readmill.store.remove).was.called()
      expect(readmill.store.remove).was.calledWith("access-token")

    it "should remove highlights from the dom", ->
      readmill.disconnect()
      expect(readmill.element.find).was.called()
      expect(readmill.element.find).was.calledWith(".annotator-hl")

  describe "#error()", ->
    it "should display an error notifiaction", ->
      target = sinon.stub Annotator, "showNotification"
      readmill.error("message")
      expect(target).was.called()
      expect(target).was.calledWith("message")
      target.restore()

  describe "#_onConnectSuccess()", ->
    it "should call @connected() with the access token and additonal params", ->
      target = sinon.stub readmill, "connected"
      params = access_token: "123456", expires: 3000
      readmill._onConnectSuccess(params)
      expect(target).was.called()
      expect(target).was.calledWith("123456", params)

  describe "#_onConnectError()", ->
    it "should call @error() with the error message", ->
      target = sinon.stub readmill, "error"
      readmill._onConnectError("test-error")
      expect(target).was.called()
      expect(target).was.calledWith("test-error")

  describe "#_onMeSuccess()", ->
    beforeEach ->
      sinon.stub readmill, "lookupReading"

    it "should assign the @user data", ->
      user = {}
      readmill._onMeSuccess(user)
      expect(readmill.user).to.equal(user)

  describe "#_onMeError()", ->
    it "should call @error() with the error message", ->
      target = sinon.stub readmill, "error"
      readmill._onMeError()
      expect(target).was.called()
      expect(target).was.calledWith("Unable to fetch user info from Readmill")

  describe "#_onBookSuccess()", ->
    it "should extend @book with the response data", ->
      target = sinon.stub jQuery, "extend"
      book = id: 1
      readmill._onBookSuccess(book)
      expect(target).was.called()
      expect(target).was.calledWith(readmill.book, book)
      target.restore()

  describe "#_onBookError()", ->
    it "should call @error() with the error message", ->
      target = sinon.stub readmill, "error"
      readmill._onBookError()
      expect(target).was.called()
      expect(target).was.calledWith("Unable to fetch book info from Readmill")

  describe "#_onCreateReadingSuccess()", ->
    body = null
    promise = null

    beforeEach ->
      promise = sinon.createPromiseStub()
      sinon.stub(readmill.client, "request").returns(promise)
      body = location: "http://api.readmill.com/reading/1"

    it "should request the reading resource if location is present", ->
      readmill._onCreateReadingSuccess(body)
      expect(readmill.client.request).was.called()
      expect(readmill.client.request.args[0][0]).to.eql(url: "http://api.readmill.com/reading/1")

    it "should register the @_onGetReadingSuccess() and @_onGetReadingError() callbacks", ->
      readmill._onCreateReadingSuccess(body)
      expect(promise.then).was.called()
      expect(promise.then).was.calledWith(readmill._onGetReadingSuccess, readmill._onGetReadingError)

    it "should call @_onGetReadingError() if the location cannot be parsed", ->
      sinon.stub(readmill, "_onGetReadingError")
      readmill._onCreateReadingSuccess({})
      expect(readmill._onGetReadingError).was.called()

  describe "#_onCreateReadingError()", ->
    it "should call @_onCreateReadingSuccess() if status is 409", ->
      body = {}
      target = sinon.stub readmill, "_onCreateReadingSuccess"
      response = status: 409, responseText: '{"location": "http://"}'

      sinon.stub(JSON, "parse").returns(body)
      sinon.stub(readmill, "error")

      readmill._onCreateReadingError(response)
      expect(target).was.called()
      expect(target).was.calledWith(body, "success", response)
      JSON.parse.restore()

    it "should call @error() with the error message if status is not 409", ->
      target = sinon.stub readmill, "error"
      readmill._onCreateReadingError(status: 422)
      expect(target).was.called()
      expect(target).was.calledWith("Unable to create a reading for this book")

  describe "#_onGetReadingSuccess()", ->
    reading = null
    promise = null

    beforeEach ->
      reading = highlights: "http://api.readmill.com/reading/1/highlights"
      promise = sinon.createPromiseStub()
      sinon.stub(readmill.view, "updateBook")
      sinon.stub(readmill.client, "getHighlights").returns(promise)

    it "should assign the reading to @book.reading", ->
      readmill._onGetReadingSuccess(reading)
      expect(readmill.book.reading).to.equal(reading)

    it "should update the view with the reading", ->
      readmill._onGetReadingSuccess(reading)
      expect(readmill.view.updateBook).was.called()

    it "should request the highlights for the reading", ->
      readmill._onGetReadingSuccess(reading)
      expect(readmill.client.getHighlights).was.called()
      expect(readmill.client.getHighlights).was.calledWith(reading.highlights)

    it "should register the @_onGetHighlightsSuccess() and @_onGetHighlightsError() callbacks", ->
      readmill._onGetReadingSuccess(reading)
      expect(promise.then).was.called()
      expect(promise.then).was.calledWith(readmill._onGetHighlightsSuccess, readmill._onGetHighlightsError)

  describe "#_onGetReadingError()", ->
    it "should call @error() with the error message", ->
      target = sinon.stub readmill, "error"
      readmill._onGetReadingError()
      expect(target).was.called()
      expect(target).was.calledWith("Unable to create a reading for this book")

  describe "#_onGetHighlightsSuccess()", ->
    highlights  = null
    promises    = null
    whenPromise = null

    beforeEach ->
      highlights = [{}, {}, {}]
      promises = [
        sinon.createPromiseStub()
        sinon.createPromiseStub()
        sinon.createPromiseStub()
      ]
      cloned = promises.slice()
      promises[1].state.returns("rejected")
      sinon.stub Readmill.utils, "annotationFromHighlight", ->
        cloned.shift()
      whenPromise = sinon.createPromiseStub()
      sinon.stub(jQuery, "when").returns(whenPromise)

    afterEach ->
      jQuery.when.restore()
      Readmill.utils.annotationFromHighlight.restore()

    it "should parse the highlights", ->
      readmill._onGetHighlightsSuccess(highlights)
      target = Readmill.utils.annotationFromHighlight
      expect(target).was.called()
      expect(target.callCount).to.equal(3)

    it "should filter out rejected annotations", ->
      readmill._onGetHighlightsSuccess(highlights)
      target = jQuery.when
      expect(target).was.called()
      expect(target.args[0].length).to.equal(2)
      expect(target).was.calledWith(promises[0], promises[2])

    it "should load the annotations into the annotator", ->
      readmill.annotator = loadAnnotations: sinon.spy()

      annotations = [{}, {}, {}]
      readmill._onGetHighlightsSuccess(highlights)
      whenPromise.done.args[0][0].apply(null, annotations)

      expect(readmill.annotator.loadAnnotations).was.called()
      expect(readmill.annotator.loadAnnotations).was.calledWith(annotations)

  describe "#_onGetHighlightsError()", ->
    it "should call @error() with the error message", ->
      target = sinon.stub readmill, "error"
      readmill._onGetHighlightsError()
      expect(target).was.called()
      expect(target).was.calledWith("Unable to fetch highlights for reading")

  describe "#_onCreateHighlight()", ->
    promise = null
    annotation = null
    response = null
    highlight = null

    beforeEach ->
      promise = sinon.createPromiseStub()
      annotation = text: "this is an annotation comment"
      response = location: "http://api.readmill.com/highlight/1"
      highlight =
        id: "1"
        uri: "http://api.readmill.com/highlight/1"
        comments: "http://api.readmill.com/highlight/1/comments"

      sinon.stub(readmill, "_onAnnotationUpdated")
      sinon.stub(readmill.client, "request").returns(promise)

    it "should request the newly created highlight", ->
      readmill._onCreateHighlight(annotation, response)
      expect(readmill.client.request).was.called()
      expect(readmill.client.request).was.calledWith(url: response.location)

    it "should store the id, commentsUrl and highlightUrl on the annotation", ->
      readmill._onCreateHighlight(annotation, response)
      promise.done.args[0][0](highlight)
      expect(annotation).to.have.property("id", annotation.id)
      expect(annotation).to.have.property("highlightUrl", annotation.uri)
      expect(annotation).to.have.property("commentsUrl", annotation.comments)

    it "should create the comment on the highlight", ->
      readmill._onCreateHighlight(annotation, response)
      promise.done.args[0][0](highlight)
      expect(readmill._onAnnotationUpdated).was.called()
      expect(readmill._onAnnotationUpdated).was.calledWith(annotation)

  describe "#_onAnnotationCreated()", ->
    promise = null
    proxied = null
    annotation = {}

    beforeEach ->
      promise = sinon.createPromiseStub()
      proxied = sinon.spy()
      readmill.book =
        id: "32"
        url: "http://"
        reading: {highlights: "http://"}
      sinon.stub(readmill, "lookupBook").returns(sinon.createPromiseStub())
      sinon.stub(readmill.client, "isAuthorized").returns(true)
      sinon.stub(readmill.client, "createHighlight").returns(promise)
      sinon.stub(jQuery, "proxy").returns(proxied)

    afterEach ->
      jQuery.proxy.restore()

    it "should create a callback function with the annotation as the first arg", ->
      readmill._onAnnotationCreated(annotation)
      expect(jQuery.proxy).was.called()
      expect(jQuery.proxy).was.calledWith(readmill, "_onCreateHighlight", annotation)

    it "should try and create a new annotation", ->
      readmill._onAnnotationCreated(annotation)
      target = readmill.client.createHighlight
      expect(target).was.called()
      expect(target).was.calledWith(readmill.book.reading.highlights)

    it "should register success and error handlers", ->
      readmill._onAnnotationCreated(annotation)
      expect(promise.done).was.called()
      expect(promise.done).was.calledWith(proxied)
      expect(promise.fail).was.called()
      expect(promise.fail).was.calledWith(readmill._onAnnotationCreatedError)

    it "should push the annotation into the @unsaved array if unauthed or no book", ->
      readmill.book = {}
      readmill._onAnnotationCreated(annotation)
      expect(readmill.unsaved).to.eql([annotation])

    it "should call @connect if unauthed", ->
      readmill.client.isAuthorized.returns(false)
      target = sinon.stub readmill, "connect"
      readmill._onAnnotationCreated(annotation)
      expect(target).was.called()

    it "should look up the book and retry if no book", ->
      readmill.book = {}
      target = readmill.lookupBook
      readmill._onAnnotationCreated(annotation)
      expect(target).was.called()

  describe "#_onAnnotationCreatedError()", ->
    it "should call @error() with the error message", ->
      target = sinon.stub readmill, "error"
      readmill._onAnnotationCreatedError()
      expect(target).was.called()
      expect(target).was.calledWith("Unable to save annotation to Readmill")

  describe "#_onAnnotationUpdated()", ->
    annotation = null
    promise = null

    beforeEach ->
      promise = sinon.createPromiseStub()
      annotation =
        text: "Annotation Comment"
      sinon.stub(readmill.client, "createComment").returns(promise)
      sinon.stub(readmill.client, "updateComment").returns(promise)

    it "should update the comment if annotation.commentUrl is present", ->
      target = readmill.client.updateComment
      annotation.commentUrl = "http://api.readmill.com/comments/1"
      readmill._onAnnotationUpdated(annotation)
      expect(target).was.called()
      expect(target).was.calledWith("http://api.readmill.com/comments/1")

    it "should create the comment if annotation.commentUrl is not present", ->
      target = readmill.client.createComment
      annotation.commentsUrl = "http://api.readmill.com/comments/"
      readmill._onAnnotationUpdated(annotation)
      expect(target).was.called()
      expect(target).was.calledWith("http://api.readmill.com/comments/")

    it "should regsiter a success hander if annotation is created", ->
      target = readmill.client.createComment
      annotation.commentsUrl = "http://api.readmill.com/comments/"
      readmill._onAnnotationUpdated(annotation)
      expect(promise.done).was.called()

    it "should register an error handler", ->
      target = readmill.client.createComment
      annotation.commentsUrl = "http://api.readmill.com/comments/"
      readmill._onAnnotationUpdated(annotation)
      expect(promise.fail).was.called()
      expect(promise.fail).was.calledWith(readmill._onAnnotationUpdatedError)

  describe "#_onAnnotationUpdatedError()", ->
    it "should call @error() with the error message", ->
      target = sinon.stub readmill, "error"
      readmill._onAnnotationUpdatedError()
      expect(target).was.called()
      expect(target).was.calledWith("Unable to update annotation in Readmill")

  describe "#_onAnnotationDeleted()", ->
    promise = null

    beforeEach ->
      promise = sinon.createPromiseStub()
      sinon.stub(readmill.client, "deleteHighlight").returns(promise)

    it "should delete the highlight if annotation.highlightUrl is present", ->
      readmill._onAnnotationDeleted(highlightUrl: "http://")
      expect(readmill.client.deleteHighlight).was.called()
      expect(readmill.client.deleteHighlight).was.calledWith("http://")

    it "should register an error callback", ->
      readmill._onAnnotationDeleted(highlightUrl: "http://")
      expect(promise.fail).was.called()
      expect(promise.fail).was.calledWith(readmill._onAnnotationDeletedError)

    it "should do nothing if annotation.highlightUrl is not present", ->
      readmill._onAnnotationDeleted({})
      expect(readmill.client.deleteHighlight).was.notCalled()

  describe "#_onAnnotationDeletedError()", ->
    it "should call @error() with the error message", ->
      target = sinon.stub readmill, "error"
      readmill._onAnnotationDeletedError()
      expect(target).was.called()
      expect(target).was.calledWith("Unable to delete annotation on Readmill")
