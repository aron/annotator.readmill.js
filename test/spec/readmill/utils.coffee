describe "utils", ->
  utils  = Annotator.Readmill.utils
  jQuery = Annotator.$
  fakeProxy = null
  annotation = null


  beforeEach ->
    fakeProxy = ->
    sinon.stub(jQuery, "proxy").returns fakeProxy
    annotation =
      ranges: []
      text: "This is an annotation comment"
      quote: "some highlighted text"

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

  describe "#highlightFromAnnotation()", ->
    it "should parse the annotation and return a highlight", ->
      target = utils.highlightFromAnnotation(annotation)
      expect(target).to.have.property("pre", "[]")
      expect(target).to.have.property("content", annotation.quote)

  describe "#commentFromAnnotation()", ->
    it "should parse the annotation and return a comment", ->
      target = utils.commentFromAnnotation(annotation)
      expect(target).to.have.property("content", annotation.text)

  describe "#annotationFromHighlight()", ->
    highlight = null
    client    = null
    promise   = null

    beforeEach ->
      highlight =
        pre: "[]"
        uri: "http://api.readmill.com/highlight/1"
        content: "A nice piece of highlighted text"
        comments: "http://api.readmill.com/highlight/1/comments"
      promise =
        done: sinon.stub()
        fail: sinon.stub()
      promise.done.returns(promise)
      promise.fail.returns(promise)
      client =
        request: sinon.stub().returns(promise)

    it "should return a jQuery.Deferred() promise", ->
      target = utils.annotationFromHighlight(highlight, client)
      expect(target).to.have.property("done")
      expect(target).to.have.property("fail")

    it "should request the highlight comments from the client", ->
      target = utils.annotationFromHighlight(highlight, client)
      expect(client.request).was.called()
      expect(client.request.args[0][0]).to.eql(url: highlight.comments)

    it "should resolve the deferred when the request completes", ->
      target = utils.annotationFromHighlight(highlight, client)
      promise.done.args[0][0]([])
      expect(target.state()).to.equal("resolved")

    it "should extract the content and uri from the first comment", ->
      target = utils.annotationFromHighlight(highlight, client)
      target.done (annotation) ->
        expect(annotation.text).to.equal("a")
        expect(annotation.commentUrl).to.equal("1")
      promise.done.args[0][0]([{content: "a", uri: "1"}, {content: "b", uri: "2"}])

    it "should call reject immediately if parsing fails", ->
      highlight.pre = ""
      target = utils.annotationFromHighlight(highlight, client)
      expect(target.state()).to.equal("rejected")
