describe "utils", ->
  utils  = Annotator.Readmill.utils
  jQuery = Annotator.$
  fakeProxy = null
  annotation = null

  beforeEach ->
    fakeProxy = ->
    sinon.stub(jQuery, "proxy").returns fakeProxy
    annotation =
      id: 1
      page: "http://page"
      ranges: [{start: "/p", end: "/p", startOffset: 0, endOffset: 1}]
      highlights: [],
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

  describe "", ->
    nodes  = null
    target = null

    beforeEach ->
      nodes = jQuery """
      <div>this is the <span>start of the tex</span>t.<span> this is selected.</span> this<span> is</span> the end</div>
      """
      target = nodes.find("span:nth-child(2)")[0]

    describe "#preText()", ->
      it "should extract the text from nodes prior to the highlight", ->
        expect(utils.preText(target)).to.equal("this is the start of the text.")

    describe "#postText()", ->
      it "should extract the text from nodes after to the highlight", ->
        expect(utils.postText(target)).to.equal(" this is the end")

  describe "#highlightFromAnnotation()", ->
    beforeEach ->
      sinon.stub(utils, 'postText').returns('post')
      sinon.stub(utils, 'preText').returns('pre')

    afterEach ->
      utils.postText.restore()
      utils.preText.restore()

    it "should parse the annotation and return a highlight", ->
      target = utils.highlightFromAnnotation(annotation)
      expect(target).to.have.property("locators").to.have.property("pre", "pre")
      expect(target).to.have.property("locators").to.have.property("post", "post")
      expect(target).to.have.property("locators").to.have.property("xpath")
      expect(target).to.have.property("locators").to.have.property("file_id", "http://page")
      expect(target).to.have.property("content", annotation.quote)
      expect(target).to.have.property("id", annotation.id)

  describe "#commentFromAnnotation()", ->
    it "should parse the annotation and return a comment", ->
      target = utils.commentFromAnnotation(annotation)
      expect(target).to.have.property("content", annotation.text)

  describe "#annotationFromHighlight()", ->
    xpath     = null
    highlight = null
    client    = null
    promise   = null

    beforeEach ->
      xpath = 
        start: "/p"
        startOffset: 0
        end: "/p"
        endOffset: 10

      highlight =
        id: 1
        locators:
          xpath: xpath
          file_id: "http://page"
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
        expect(annotation.page).to.equal("http://page")
        expect(annotation.ranges).to.eql([xpath])
      promise.done.args[0][0]([{content: "a", uri: "1"}, {content: "b", uri: "2"}])

    it "should call reject immediately if parsing fails", ->
      highlight.locators = {}
      target = utils.annotationFromHighlight(highlight, client)
      expect(target.state()).to.equal("rejected")

    it "should fallback to parsing the \"pre\" token", ->
      highlight.pre = "[]"
      target = utils.annotationFromHighlight(highlight, client)
      target.done (annotation) ->
        expect(annotation.ranges).to.eql([xpath])
