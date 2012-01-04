describe "Readmill", ->
  jQuery   = Annotator.$
  Readmill = Annotator.Readmill
  readmill = null

  beforeEach ->
    readmill = new Readmill $("<div />"),
      book: {}
      clientId: "12345"
      callbackUri: "http://localhost/callback.html"

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
    sinon.stub(Readmill.Store.prototype, "get").returns("abcdefg")

    target = new Readmill $("<div />"),
      book: {}
      clientId: "12345"
      callbackUri: "http://localhost/callback.html"
    expect(target.connected).was.called()
    expect(target.connected).was.calledWith("abcdefg")

    Readmill.prototype.connected.restore()
    Readmill.Store.prototype.get.restore()

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
      promise = sinon.stub jQuery.Deferred().promise()
      promise.done.returns promise
      promise.then.returns promise
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
      bookPromise = sinon.stub jQuery.Deferred().promise()
      bookPromise.done.returns bookPromise
      readingPromise = sinon.stub jQuery.Deferred().promise()
      readingPromise.then.returns readingPromise

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

  describe "#connected()", ->

  describe "#disconnect()", ->

  describe "#error()", ->

  describe "#_onConnectSuccess()", ->

  describe "#_onConnectError()", ->

  describe "#_onMeSuccess()", ->

  describe "#_onMeError()", ->

  describe "#_onBookSuccess()", ->

  describe "#_onBookError()", ->

  describe "#_onCreateReadingSuccess()", ->

  describe "#_onCreateReadingError()", ->

  describe "#_onGetReadingSuccess()", ->

  describe "#_onGetReadingError()", ->

  describe "#_onGetHighlightsSuccess()", ->

  describe "#_onGetHighlightsError()", ->

  describe "#_onCreateHighlight()", ->

  describe "#_onAnnotationCreated()", ->

  describe "#_onAnnotationUpdated()", ->

  describe "#_onAnnotationDeleted()", ->
