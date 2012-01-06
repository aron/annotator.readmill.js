.PHONY: watch proxy serve build pkg

version = 0.1.0
output = lib/annotator.readmill.min.js
coffee = `npm bin`/coffee
uglify = `npm bin`/uglifyjs
header = \
"/*  Readmill Annotator Plugin - v${version}\n \
  *  Copyright 2011, Aron Carroll\n \
  *  Released under the MIT license\n \
  *  More Information: http://github.com/aron/readmill.annotator.js\n \
  */"

watch:
	${coffee} --watch --output ./lib ./src

proxy:
	PORT=8080 \
	PROXY_DOMAIN=http://localhost:8080 \
	READMILL_CLIENT_CALLBACK=http://localhost:8000/callback.html \
	${coffee} proxy.coffee

serve:
	python -m SimpleHTTPServer 8000

build:
	echo ${header} > ${output} && \
	cat -s src/readmill.coffee src/readmill/*.coffee | \
	${coffee} --stdio --print | \
	${uglify} >> ${output} && \
	echo "" >> ${output}

pkg: build
	zip -jJ annotator.readmill.${version}.zip \
	lib/annotator.readmill.min.js \
	css/annotator.readmill.css
