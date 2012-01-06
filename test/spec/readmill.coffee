describe "Readmill", ->
  jQuery   = Annotator.$
  Readmill = Annotator.Readmill
  readmill = null

  beforeEach ->
    sinon.stub(Readmill.Store.prototype, "get").returns(null)
    readmill = new Readmill $("<div />"),
      book: {}
      clientId: "12345"
      callbackUri: "http://localhost/callback.html"

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
      callbackUri: "http://localhost/callback.html"
    expect(target.connected).was.called()
    expect(target.connected).was.calledWith("abcdefg")
    Readmill.prototype.connected.restore()

  it "should call @connected() with the access token if in localStorage", ->
    sinon.stub(Readmill.prototype, "connected")
    Readmill.Store.prototype.get.returns("abcdefg")

    target = new Readmill $("<div />"),
      book: {}
      clientId: "12345"
      callbackUri: "http://localhost/callback.html"
    expect(target.connected).was.called()
    expect(target.connected).was.calledWith("abcdefg")

    Readmill.prototype.connected.restore()

  it "should raise an Error if any required parameters are missing", ->
    target = ->
      target = new Readmill $("<div />"),
        clientId: "12345"
        callbackUri: "http://localhost/callback.html"
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

    it "should get the reading for the current book", ->
      readmill._onMeSuccess({})
      expect(readmill.lookupReading).was.called()

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
    it "should extract the location permalink from the response body"
    it "should request the reading resoource"
    it "should register the @_onGetReadingSuccess() and @_onGetReadingError() callbacks"
    it "should call @_onGetReadingError() if the location cannot be parsed"

  describe "#_onCreateReadingError()", ->
    it "should call @_onCreateReadingSuccess() if status is 409", ->
      sinon.stub readmill, "error"
      target = sinon.stub readmill, "_onCreateReadingSuccess"
      response = status: 409
      readmill._onCreateReadingError(response)
      expect(target).was.called()
      expect(target).was.calledWith(null, null, response)

    it "should call @error() with the error message if status is not 409", ->
      target = sinon.stub readmill, "error"
      readmill._onCreateReadingError(status: 422)
      expect(target).was.called()
      expect(target).was.calledWith("Unable to create a reading for this book")

  describe "#_onGetReadingSuccess()", ->
    it "should assign the reading to @book.reading"
    it "should request the highlights for the reading"
    it "should register the @_onGetHighlightsSuccess() and @_onGetHighlightsError() callbacks"

  describe "#_onGetReadingError()", ->
    it "should call @error() with the error message", ->
      target = sinon.stub readmill, "error"
      readmill._onGetReadingError()
      expect(target).was.called()
      expect(target).was.calledWith("Unable to create a reading for this book")

  describe "#_onGetHighlightsSuccess()", ->
    it "should parse the highlights"
    it "should filter out rejected annotations"
    it "should load the annotations into the annotator"

  describe "#_onGetHighlightsError()", ->
    it "should call @error() with the error message", ->
      target = sinon.stub readmill, "error"
      readmill._onGetHighlightsError()
      expect(target).was.called()
      expect(target).was.calledWith("Unable to fetch highlights for reading")

  describe "#_onCreateHighlight()", ->
    it "should be refactored"

  describe "#_onAnnotationCreated()", ->
    it "should create a callback function with the annotation as the first arg"
    it "should try and create a new annotation"
    it "should register success and error handlers"
    it "should push the annotation into the @unsaved array if unauthed or no book"
    it "should call @connect if unauthed"
    it "should look up the book and retry if no book"
    

  describe "#_onAnnotationUpdated()", ->
    it "should update the comment if annotation.commentUrl is present"
    it "should create the comment if annotation.commentUrl is not present"
    it "should regsiter a success hander if annotation is created"
    it "should register an error handler"

  describe "#_onAnnotationDeleted()", ->
    it "should delete the highlight if annotation.highlightUrl is present"
    it "should do nothing if annotation.highlightUrl is not present"
    