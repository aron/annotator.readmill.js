describe "Store", ->
  Store = Annotator.Readmill.Store
  Store._localStorage = Store.localStorage
  store = null

  now = -> (new Date()).getTime()

  beforeEach ->
    store = new Store()

    Store.localStorage =
      getItem:    sinon.stub()
      setItem:    sinon.stub()
      removeItem: sinon.stub()
      clear:      sinon.stub()

  it "should create a new instance of Store", ->
    expect(store).to.be.an.instanceof(Store)

  describe ".localStorage", ->
    it "should be the window.localStorage object", ->
      expect(Store._localStorage).to.equal(window.localStorage)

  describe ".isSupported()", ->
    it "should return true if localStorage is supported", ->
      isSupported = try
        "localStorage" in window && window["localStorage"] != null
      catch e then false
      expect(Store.isSupported()).to.equal(isSupported)

  describe ".now()", ->
    it "should return the current time in milliseconds", ->
      sinon.stub(Date.prototype, "getTime").returns(123456789)
      expect(Store.now()).to.equal(123456789)
      Date.prototype.getTime.restore()

  describe "#get()", ->
    beforeEach ->
      sinon.stub(store, "remove").returns(store)
      sinon.stub(store, "checkCache").returns("\"value\"")
      sinon.stub(JSON, "parse", (x) -> x)
      Store.localStorage.getItem.returns("\"value\"")

    afterEach ->
      JSON.parse.restore()

    it "should call the localStorage.getItem() method", ->
      store.get("key")
      expect(Store.localStorage.getItem).was.called()
      expect(Store.localStorage.getItem).was.calledWith("annotator.readmill/key")

    it "should return null if not found", ->
      Store.localStorage.getItem.returns(null)
      expect(store.get("key")).to.equal(null)

    it "should check the cached value", ->
      store.get("key")
      expect(store.checkCache).was.called()
      expect(store.checkCache).was.calledWith("\"value\"")

    it "should remove the value if expired", ->
      store.checkCache.returns(null)
      store.get("key");
      expect(store.remove).was.called();
      expect(store.remove).was.calledWith("key");

    it "should parse the returned string with JSON.parse()", ->
      store.get("key")
      expect(JSON.parse).was.called()
      expect(JSON.parse).was.calledWith("\"value\"")

  describe "#set()", ->
    beforeEach ->
      sinon.stub(JSON, "stringify").returns()

    afterEach ->
      JSON.stringify.restore() if JSON.stringify.restore

    it "should set the value for the key provided", ->
      store.set("key", "value");
      expect(Store.localStorage.setItem).was.called();
      expect(Store.localStorage.setItem).was.called("annotator.readmill/key", "\"value\"");

    it "should JSON.stringify() the value", ->
      store.set("key", "value");
      expect(JSON.stringify).was.called();
      expect(JSON.stringify).was.calledWith("value");

    it "should add a cache key to the value if a time is provided", ->
      JSON.stringify.returns("\"value\"")
      sinon.stub(Store, "now").returns(10000000)
      expectedValue = "#{10000000 + 3000}#{Store.CACHE_DELIMITER}\"value\""

      store.set("key", "value", 3000)
      expect(Store.localStorage.setItem).was.called()
      expect(Store.localStorage.setItem).was.calledWith("annotator.readmill/key", expectedValue)

      Store.now.restore()

    it "should catch exceptions thrown by localStorage.setItem()", ->
      # Used by chai.js so we need to restore this here.
      JSON.stringify.restore()

      Store.localStorage.setItem.throws(new Error)
      expect(store.set("key", "value")).to.equal(store)

    it "should trigger the \"error\" event if an exception is thrown", ->
      error = new Error

      sinon.stub(store, "publish")
      Store.localStorage.setItem.throws(error)

      store.set("key", "value");

      expect(store.publish).was.called();
      expect(store.publish).was.calledWith("error", [error, store])

  describe "#remove()", ->
    it "should remove the key from the store", ->
      store.remove("key");
      expect(Store.localStorage.removeItem).was.called();
      expect(Store.localStorage.removeItem).was.calledWith("annotator.readmill/key");

  describe "#checkCache()", ->
    it "should return the value if no cache is present", ->
      expect(store.checkCache("value")).to.equal("value")

    it "should return the value if the expiry time is greater than now", ->
      value = "#{now() + 10000}#{Store.CACHE_DELIMITER}value"
      expect(store.checkCache(value)).to.equal("value")

    it "should return null if the expiry time is less than now", ->
      value = "#{now() - 10000}#{Store.CACHE_DELIMITER}value"
      expect(store.checkCache(value)).to.be.null
