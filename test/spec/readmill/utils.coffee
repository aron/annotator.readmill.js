describe "utils", ->
  utils = Annotator.Readmill.utils

  describe "serializeQueryString()", ->
    it "should serialise an object literal into a query string", ->
      string = utils.serializeQueryString(dog: "woof", cat: "meow")
      assert.equal(string, "dog=woof&cat=meow")
    it "should escape special characters", ->
      string = utils.serializeQueryString("nested[string]": "is good")
      assert.equal(string, "nested%5Bstring%5D=is%20good")
    it "should allow delimiters to be specified as additional arguments", ->
      string = utils.serializeQueryString(dog: "woof", cat: "meow", ";", ",")
      assert.equal(string, "dog,woof;cat,meow")

  describe "parseQueryString()", ->
    it "should parse a query string into an object literal", ->
      parsed = utils.parseQueryString("dog=woof&cat=meow")
      assert.deepEqual(parsed, dog: "woof", cat: "meow")
    it "should escape special characters", ->
      parsed = utils.parseQueryString("nested%5Bstring%5D=is%20good")
      assert.deepEqual(parsed, "nested[string]": "is good")
    it "should allow delimiters to be specified as additional arguments", ->
      parsed = utils.parseQueryString("dog,woof;cat,meow", ";", ",")
      assert.deepEqual(parsed, dog: "woof", cat: "meow")

    