describe "Auth", ->
  jQuery = Annotator.$
  Auth = Annotator.Readmill.Auth
  auth = null

  beforeEach ->
    auth = new Auth
      clientId: "12345"
      callbackUri: "http://localhost:8000/callback.html"

  it "should create a new instance of Auth", ->
    expect(auth).to.be.an.instanceof Auth

  it "should allow the auth URI to be overridden", ->
    target = new Auth
      clientId: "12345"
      callbackUri: "http://localhost:8000/callback.html"
      authEndpoint: "http://localhost:8000/auth"
    expect(target.authEndpoint).to.equal "http://localhost:8000/auth"

  it "should raise an exception if @clientId is not provided", ->
    target = -> new Auth callbackUri: "http://localhost:8000/callback.html"
    expect(target).to.throw Error

  it "should raise an exception if @callbackUrl is not provided", ->
    target = -> new Auth clientId: "12345"
    expect(target).to.throw Error

  describe "#connect()", ->
    beforeEach ->
      sinon.stub auth, "openWindow"

    it "should open a new popup pointing to the Auth endpoint", ->
      auth.connect()
      expect(auth.openWindow).was.called()

    it "should return a jQuery.Deferred() promise", ->
      target = auth.connect()
      expect(target).to.have.property "done"
      expect(target).to.have.property "fail"
    
    it "should set Auth.callback with the first argument bound as the deferred object", ->
      sinon.stub(jQuery, "proxy").returns("stubbed")
      auth.connect()

      expect(jQuery.proxy).was.called()
      expect(jQuery.proxy).was.calledWith(auth.callback, auth)
      expect(jQuery.proxy.args[0][2]).to.have.property("resolve")
      expect(jQuery.proxy.args[0][2]).to.have.property("reject")
      expect(Auth.callback).to.equal "stubbed"
      
      jQuery.proxy.restore()

  describe "#callback()", ->
    deferred = null

    beforeEach ->
      deferred = sinon.stub(new jQuery.Deferred())
      auth.popup =
        close: sinon.spy()
        location: {hash: "#access_token=12345"}

    it "should close the popup window", ->
      auth.callback(deferred)
      expect(auth.popup.close).was.called()

    it "should parse the popup location hash", ->
      utils = Annotator.Readmill.utils
      sinon.stub(utils, "parseQueryString").returns({})

      auth.callback(deferred)
      expect(utils.parseQueryString).was.called()
      expect(utils.parseQueryString).was.calledWith("access_token=12345")

      utils.parseQueryString.restore()

    it "should call deferred.resolve() if an access token is present", ->
      auth.callback(deferred)
      expect(deferred.resolve).was.called()
      expect(deferred.resolve).was.calledWith(access_token: "12345")

    it "should call deferred.reject() if an access token is not present", ->
      auth.popup.location.hash = "#error=test-error"
      auth.callback(deferred)
      expect(deferred.reject).was.called()
      expect(deferred.reject).was.calledWith("test-error")

  describe "#openWindow()", ->
    it "should call window.open()", ->
      window.open = sinon.spy()
      auth.openWindow(window.location.href)
      expect(window.open).was.called()
      expect(window.open).was.calledWith(window.location.href)
      delete window.open

    it "should allow a width and height to be specified", ->
      window.open = sinon.spy()
      auth.openWindow(window.location.href, 100, 200)
      expect(window.open).was.called()
      expect(window.open).was.calledWith(window.location.href, "readmill-connect")
      expect(window.open.args[0][2]).to.include "width=100"
      expect(window.open.args[0][2]).to.include "height=200"
      delete window.open

    it "should return a window instance", ->
      target = auth.openWindow(window.location.href)
      expect(target).to.have.property "close"
      target.close()
