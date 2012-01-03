describe "utils", ->
  utils  = Annotator.Readmill.utils
  jQuery = Annotator.$
  fakeProxy = null

  beforeEach ->
    fakeProxy = ->
    sinon.stub(jQuery, "proxy").returns fakeProxy

  afterEach ->
    jQuery.proxy.restore()

  describe "proxyHandlers", ->
    it "should bind all methods beginning with '_on' to the parent scope", ->
      obj =
        _onSubmit: ->
        _onClick: ->
        prop: "string"
      utils.proxyHandlers obj

      expect(obj._onSubmit).to.equal fakeProxy
      expect(obj._onClick).to.equal fakeProxy
      expect(obj.prop).to.equal "string"

    it "should not try to bind non functions", ->
      obj = _onSubmit: "string"
      utils.proxyHandlers obj

      expect(obj._onSubmit).to.equal "string"

    it "should allow the prefix to be provided", ->
      obj =
        handlerSubmit: ->
        prop: "string"
      utils.proxyHandlers obj, "handler"

      expect(obj.handlerSubmit).to.equal fakeProxy
      expect(obj.prop).to.equal "string"

  describe "serializeQueryString()", ->
    it "should serialise an object literal into a query string", ->
      string = utils.serializeQueryString(dog: "woof", cat: "meow")
      expect(string).to.equal("dog=woof&cat=meow")
    it "should escape special characters", ->
      string = utils.serializeQueryString("nested[string]": "is good")
      expect(string).to.equal("nested%5Bstring%5D=is%20good")
    it "should allow delimiters to be specified as additional arguments", ->
      string = utils.serializeQueryString(dog: "woof", cat: "meow", ";", ",")
      expect(string).to.equal("dog,woof;cat,meow")

  describe "parseQueryString()", ->
    it "should parse a query string into an object literal", ->
      parsed = utils.parseQueryString("dog=woof&cat=meow")
      expect(parsed).to.eql(dog: "woof", cat: "meow")
    it "should escape special characters", ->
      parsed = utils.parseQueryString("nested%5Bstring%5D=is%20good")
      expect(parsed).to.eql("nested[string]": "is good")
    it "should allow delimiters to be specified as additional arguments", ->
      parsed = utils.parseQueryString("dog,woof;cat,meow", ";", ",")
      expect(parsed).to.eql(dog: "woof", cat: "meow")

