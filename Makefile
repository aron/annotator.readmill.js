.PHONY: watch server

watch:
	coffee -w -o ./lib ./src

server:
	PROXY_DOMAIN=http://localhost:8000 \
	READMILL_CLIENT_CALLBACK=http://localhost:8001/callback.html \
	coffee proxy.coffee
