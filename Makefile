.PHONY: watch proxy serve

watch:
	coffee -w -o ./lib ./src

proxy:
	PORT=8000 \
	PROXY_DOMAIN=http://localhost:8000 \
	READMILL_CLIENT_CALLBACK=http://localhost:8001/callback.html \
	coffee proxy.coffee

serve:
	python -m SimpleHTTPServer 8001
