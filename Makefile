.PHONY: watch proxy serve build

output = lib/annotator.readmill.min.js
coffee = `npm bin`/coffee
uglify = `npm bin`/uglifyjs
header = \
"/*  Readmill Annotator Plugin - v0.1.0\n \
  *  Copyright 2011, Aron Carroll\n \
  *  Released under the MIT license\n \
  *  More Information: http://github.com/aron/readmill.annotator.js\n \
  */"

watch:
	${coffee} --watch --output ./lib ./src

proxy:
	PORT=8080 \
	PROXY_DOMAIN=http://localhost:8080 \
	READMILL_CLIENT_CALLBACK=http://localhost:8080/callback.html \
	${coffee} proxy.coffee

serve:
	python -m SimpleHTTPServer 8000

build:
	echo ${header} > ${output} && \
	cat -s src/readmill.coffee src/readmill/*.coffee | \
	${coffee} --stdio --print | \
	${uglify} >> ${output} && \
	echo "" >> ${output}
