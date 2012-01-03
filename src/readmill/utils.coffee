jQuery = Annotator.$

# # Useful utility functions.
Annotator.Readmill.utils =
  # Public: Binds context of handler methods (beginning with "_on") on the
  # provided object to the provided object. This is useful for binding scope
  # on multiple methods without having to use CoffeeScripts => syntax which
  # will add a new __bind() call for every method.
  #
  # obj    - Object to bind methods.
  # prefix - An alternative prefix string (default: "_on").
  #
  # Examples
  #
  #   class Handler
  #     constructor: ->
  #       utils.proxyHandlers this
  #       jQuery("body").bind
  #         click: _onClick, submit: _onSubmit, change: _onChange
  #     log: (msg) -> console.log msg
  #     _onClick:  -> @log "clicked"
  #     _onSubmit: -> @log "submitted"
  #     _onChange: -> @log "changed"
  #
  # Returns 
  proxyHandlers: (obj, prefix="_on") ->
    for key, value of obj
      if key.indexOf(prefix) is 0 and typeof value is "function"
        obj[key] = jQuery.proxy obj, key
    obj

  # Public: Serializes an object literal into a query string suitable
  # for use in a url. Escapes key and value parameters into url safe
  # entities.
  #
  # obj - An object to serailize.
  # sep - The seperator to join parameters (default: "&")
  # eq  - The seperator between key and value (default: "=")
  #
  # Examples
  #
  #   utils.serializeQueryString(dog: "woof", cat: "meow")
  #   #=> "dog=woof&cat=meow"
  #
  #   utils.serializeQueryString(dog: "woof", cat: "meow", "\n", ": ")
  #   #=> "dog: woof\ncat: meow"
  #
  # Returns newly created string.
  serializeQueryString: (obj, sep="&", eq="=") ->
    esc = window.encodeURIComponent
    ("#{esc(key)}#{eq}#{esc(value)}" for own key, value of obj).join(sep)

  # Public: parses a query string extracted from a url. Also decodes
  # any escaped key/values.
  #
  # obj - An string to parse.
  # sep - The seperator to join parameters (default: "&")
  # eq  - The seperator between key and value (default: "=")
  #
  # Examples
  #
  #   utils.parseQueryString("dog=woof&cat=meow")
  #   #=> {dog: "woof", cat: "meow"}
  #
  # Returns an object of key value pairs.
  parseQueryString: (str, sep="&", eq="=") ->
    obj = {}
    decode = window.decodeURIComponent
    for param in str.split(sep)
      [key, value] = param.split(eq)
      obj[decode(key)] = decode value
    obj
