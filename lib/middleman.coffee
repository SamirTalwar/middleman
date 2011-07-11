http = require 'http'
url = require 'url'

class Middleman
    hostname = undefined
    port = undefined

    server = http.createServer (clientRequest, clientResponse) ->
        options =
            host: hostname
            port: port
            method: clientRequest.method
            path: clientRequest.url
            headers: clientRequest.headers

        serverRequest = http.request options, (serverResponse) ->
            serverResponse.on 'data', (chunk) -> clientResponse.write chunk
            serverResponse.on 'end', -> clientResponse.end()

        clientRequest.on 'data', (chunk) -> serverRequest.write chunk
        clientRequest.on 'end', -> serverRequest.end()

    constructor: (proxiedUrl) ->
        urlParts = url.parse proxiedUrl
        hostname = urlParts.hostname
        port = urlParts.port

    listen: (args...) ->
        server.listen args...

    close: ->
        server.close()

module.exports = Middleman
