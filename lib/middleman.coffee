#!/usr/bin/env coffee

http = require 'http'
https = require 'https'
url = require 'url'

class MiddleMan
    destination = {}

    server = http.createServer (clientRequest, clientResponse) ->
        options =
            host: destination.hostname
            port: destination.port
            method: clientRequest.method
            path: clientRequest.url
            headers: clientRequest.headers

        request = { 'http:': http.request, 'https:': https.request }[destination.protocol]
        serverRequest = request options, (serverResponse) ->
            clientResponse.writeHead serverResponse.statusCode, serverResponse.headers
            serverResponse.on 'data', (chunk) -> clientResponse.write chunk
            serverResponse.on 'end', -> clientResponse.end()

        clientRequest.on 'data', (chunk) -> serverRequest.write chunk
        clientRequest.on 'end', -> serverRequest.end()

    constructor: (proxiedUrl) ->
        destination = url.parse proxiedUrl

    listen: (args...) ->
        server.listen args...

    close: ->
        server.close()

module.exports = MiddleMan
