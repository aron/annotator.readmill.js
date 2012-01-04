.PHONY: watch proxy serve build

coffee = `npm bin`/coffee

watch:
	${coffee} --watch --output ./lib ./src

proxy:
	PORT=8000 \
	PROXY_DOMAIN=http://localhost:8000 \
	READMILL_CLIENT_CALLBACK=http://localhost:8001/callback.html \
	${coffee} proxy.coffee

serve:
	python -m SimpleHTTPServer 8001

build:
	cat -s src/readmill.coffee src/readmill/*.coffee | \
	${coffee} --stdio --print > lib/annotator.readmill.js
