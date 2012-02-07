fs   = require "fs"
FFI  = require "node-ffi"
libc = new FFI.Library(null, "system": ["int32", ["string"]])
run  = libc.system
pkg  = require "./package"

VERSION = pkg.version
OUTPUT = "pkg/annotator.readmill.min.js"
STYLES = "pkg/annotator.readmill.css"
COFFEE = "node_modules/.bin/coffee"
UGLIFY = "node_modules/.bin/uglifyjs"
HEADER = """
/*  Readmill Annotator Plugin - v#{VERSION}
 *  Copyright 2011, Aron Carroll
 *  Released under the MIT license
 *  More Information: http://github.com/aron/readmill.annotator.js
 */
"""

task "watch", "Watch the coffee directories and output to ./lib", ->
  run "#{COFFEE} --watch --output ./lib ./src"

task "serve", "Serve the example files using a python server", ->
  run "python -m SimpleHTTPServer 8000"
  run "open http://localhost:8000/index.html"

task "proxy", "Run the proxy server locally on port 8080", ->
  run """
  PORT=8080 \
  PROXY_DOMAIN=http://localhost:8080 \
  READMILL_CLIENT_CALLBACK=http://localhost:8000/callback.html \
  ${coffee} proxy.coffee
  """

task "test", "Open the test suite in the browser", ->
  invoke "serve"
  run "open http://localhost:8000/test/index.html"

task "build", "Compile production ready files", ->
  run "mkdir -p pkg"
  run """
  echo "#{HEADER}" > #{OUTPUT} && 
  find ./src/readmill -not -name "utils.coffee" -type f -print | 
  xargs cat src/readmill.coffee src/readmill/utils.coffee | 
  #{COFFEE} --stdio --print | 
  #{UGLIFY} >> #{OUTPUT} && 
  echo "" >> #{OUTPUT}
  """
  utils.inline ["css/annotator.readmill.css"], STYLES

task "pkg", "Build a packaged zip of production files", ->
  invoke "build"
  run "zip -jJ pkg/annotator.readmill.#{VERSION}.zip #{OUTPUT} #{STYLES}"

task "clean", "Remove all temporary pkg and lib files", ->
  run "rm -rf lib pkg"

utils = 
  dataurlify: (css) ->
    # NB: path to image is "src/..." because the CSS urls start with "../img"
    b64_str = (name) -> fs.readFileSync("src/#{name}.png").toString('base64')
    b64_url = (m...) -> "url('data:image/png;base64,#{b64_str(m[2])}')"
    css.replace(/(url\(([^)]+)\.png\))/g, b64_url)

  inline: (src, dest) ->
    run "echo '#{HEADER}' > #{dest}"
    run "cat #{src.join(' ')} >> #{dest}"
    code = fs.readFileSync(dest, 'utf8')
    fs.writeFileSync(dest, @dataurlify(code))
