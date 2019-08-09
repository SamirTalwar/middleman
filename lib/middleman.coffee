#!/usr/bin/env coffee

http = require 'http'
https = require 'https'
url = require 'url'

PORT = 8080

class MiddleMan
    destination = {}

    server = http.createServer (clientRequest, clientResponse) ->
        options =
            host: destination.hostname
            port: destination.port
            method: clientRequest.method
            path: clientRequest.url
            headers: clientRequest.headers
        options.headers.host = destination.hostname

        request = { 'http:': http.request, 'https:': https.request }[destination.protocol]
        serverRequest = request options, (serverResponse) ->
            clientResponse.writeHead serverResponse.statusCode, serverResponse.headers
            serverResponse.on 'data', (chunk) -> clientResponse.write chunk
            serverResponse.on 'end', -> clientResponse.end()

        clientRequest.on 'data', (chunk) -> serverRequest.write chunk
        clientRequest.on 'end', -> serverRequest.end()

    constructor: (proxiedUrl) ->
        destination = url.parse proxiedUrl
        unless destination.protocol and destination.hostname
            throw new Error("Invalid destination: #{destination.href}")

    listen: (args...) ->
        server.listen args...

    close: (callback) ->
        server.on 'close', callback
        server.close()

if module != require.main
    module.exports = MiddleMan
    return

if process.argv.length < 3
  process.stderr.write "Usage: #{process.argv[1]} URL [PORT]\n"
  process.exit 2

port = if process.argv[3] then parseInt(process.argv[3]) else PORT
middleman = new MiddleMan(process.argv[2])
middleman.listen(port)
