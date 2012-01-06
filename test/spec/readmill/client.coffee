describe "Client", ->
  jQuery = Annotator.$
  Client = Annotator.Readmill.Client
  client = null
  fakeDeferred = null

  beforeEach ->
    client = new Client clientId: "12345"
    fakeDeferred = sinon.stub new jQuery.Deferred()
    sinon.stub(jQuery, "ajax").returns fakeDeferred

  afterEach ->
    jQuery.ajax.restore()

  it "should create a new instance of Client", ->
    expect(client).to.be.an.instanceof Client

  it "should allow the @apiEndpoint to be overridden", ->
    target = new Client clientId: "12345", apiEndpoint: "http://localhost:8000"
    expect(target.apiEndpoint).to.equal "http://localhost:8000"

  it "should throw an exception if options.clientId is not provided", ->
    target = -> new Client()
    expect(target).to.throw Error

  describe "#request()", ->
    it "should call jQuery.ajax()", ->
      client.request(url: "")
      expect(jQuery.ajax).was.called()

  describe "#authorize()", ->
    it "should set the @accessToken property", ->
      client.authorize("abcdefg")
      expect(client.accessToken).to.equal "abcdefg"

  describe "#deauthorize()", ->
    it "should remove the @accessToken property", ->
      client.accessToken = "abcdefg"
      client.deauthorize()
      expect(client.accessToken).to.equal(null)

  describe "#isAuthorized()", ->
    it "should return true if @accessToken is present", ->
      client.accessToken = "abcdefg"
      expect(client.isAuthorized()).to.be.true

    it "should return false if @accessToken is not present", ->
      expect(client.isAuthorized()).to.be.false
