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

  describe "#lookupReading()", ->

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
