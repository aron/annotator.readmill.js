.PHONY: watch server

watch:
	coffee -w -o ./lib ./src

server:
	PROXY_DOMAIN=http://localhost:8000 coffee proxy.coffee
