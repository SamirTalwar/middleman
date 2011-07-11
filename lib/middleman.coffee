http = require 'http'
url = require 'url'

class Middleman
    hostname = undefined
    port = undefined

    server = http.createServer (clientRequest, clientResponse) ->
        req = http.request { method: 'GET', host: hostname, port: port, path: clientRequest.url }, (serverResponse) ->
            serverResponse.on 'data', (chunk) -> clientResponse.write chunk
            serverResponse.on 'end', -> clientResponse.end()
        req.end()

    constructor: (proxiedUrl) ->
        urlParts = url.parse proxiedUrl
        hostname = urlParts.hostname
        port = urlParts.port

    listen: (args...) ->
        server.listen args...

    close: ->
        server.close()

module.exports = Middleman
