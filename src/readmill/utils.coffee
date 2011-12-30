# Useful utility functions.
Annotator.Readmill.utils =
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
