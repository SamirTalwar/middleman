fs = require 'fs'
http = require 'http'
https = require 'https'
MiddleMan = require '../lib/middleman'

describe 'proxying a server', ->
    server = undefined
    middleman = undefined

    beforeEach ->
        server = undefined
        middleman = undefined

    afterEach ->
        serverClosed = not server?
        middlemanClosed = not middleman?

        if not serverClosed
            server.on 'close', -> serverClosed = true
            try
                server.close()
            catch e
                serverClosed = true

        if not middlemanClosed
            middleman.on 'close', -> middlemanClosed = true
            try
                middleman.close()
            catch e
                middlemanClosed = true

        waitsFor (-> serverClosed), 'server to close', 1000
        waitsFor (-> middlemanClosed), 'middleman to close', 1000

    it 'requests the root directory', ->
        responseBody = undefined

        server = http.createServer (request, response) ->
            response.end 'Well, hello there.\n'
        server.listen 7357, ->
            middleman = new MiddleMan('http://localhost:7357')
            middleman.listen 7358, ->
                http.get { host: 'localhost', port: 7358, path: '/' }, (response) ->
                    response.setEncoding 'utf8'
                    body = ''
                    response.on 'data', (chunk) -> body += chunk
                    response.on 'end', -> responseBody = body

        waitsFor (-> responseBody?), 'response', 1000
        runs ->
            expect(responseBody).toEqual 'Well, hello there.\n'

    it 'requests the given path', ->
        requestUrl = undefined
        responseBody = undefined

        server = http.createServer (request, response) ->
            requestUrl = request.url
            response.end 'Well, hello there.\n'
        server.listen 7357, ->
            middleman = new MiddleMan('http://localhost:7357')
            middleman.listen 7358, ->
                http.get { host: 'localhost', port: 7358, path: '/p/a/t/h?query=string#hash' }, (response) ->
                    response.setEncoding 'utf8'
                    body = ''
                    response.on 'data', (chunk) -> body += chunk
                    response.on 'end', -> responseBody = body

        waitsFor (-> requestUrl?), 'request URL', 1000
        waitsFor (-> responseBody?), 'response', 1000

        runs ->
            expect(requestUrl).toEqual '/p/a/t/h?query=string#hash'
            expect(responseBody).toEqual 'Well, hello there.\n'

    it 'handles POST requests with bodies', ->
        requestMethod = undefined
        requestBody = undefined
        responseBody = undefined

        server = http.createServer (request, response) ->
            requestMethod = request.method
            body = ''
            request.on 'data', (chunk) -> body += chunk
            request.on 'end', -> requestBody = body

            response.end 'I\'ll get you, wabbit!'
        server.listen 7357, ->
            middleman = new MiddleMan('http://localhost:7357')
            middleman.listen 7358, ->
                options = { method: 'POST', host: 'localhost', port: 7358, path: '/p/a/t/h' }
                request = http.request options, (response) ->
                    response.setEncoding 'utf8'
                    body = ''
                    response.on 'data', (chunk) -> body += chunk
                    response.on 'end', -> responseBody = body
                request.write 'What\'s up, doc?'
                request.end()

        waitsFor (-> requestMethod?), 'request method', 1000
        waitsFor (-> requestBody?), 'request body', 1000
        waitsFor (-> responseBody?), 'response', 1000

        runs ->
            expect(requestMethod).toEqual 'POST'
            expect(requestBody).toEqual 'What\'s up, doc?'
            expect(responseBody).toEqual 'I\'ll get you, wabbit!'

    it 'forwards headers from the client to the server', ->
        requestHeaders = undefined
        responseBody = undefined

        server = http.createServer (request, response) ->
            requestHeaders = request.headers
            response.end 'Well, hello there.\n'
        server.listen 7357, ->
            middleman = new MiddleMan('http://localhost:7357')
            middleman.listen 7358, ->
                options =
                    host: 'localhost'
                    port: 7358
                    path: '/p/a/t/h'
                    headers:
                        'host': 'www.example.com' # this will be thrown away
                        'content-type': 'text/plain'
                        'content-length': '0'
                        'accept': 'application/json'

                http.get options, (response) ->
                    response.setEncoding 'utf8'
                    body = ''
                    response.on 'data', (chunk) -> body += chunk
                    response.on 'end', -> responseBody = body

        waitsFor (-> requestHeaders?), 'request headers', 1000
        waitsFor (-> responseBody?), 'response', 1000

        runs ->
            expect(requestHeaders).toEqual {
                'host': 'localhost' # this is reset by the proxy
                'content-type': 'text/plain'
                'content-length': '0'
                'accept': 'application/json'
                'connection': 'close'
            }
            expect(responseBody).toEqual 'Well, hello there.\n'

    it 'forwards headers from the server to the client', ->
        responseStatusCode = undefined
        responseHeaders = undefined

        server = http.createServer (request, response) ->
            response.writeHead '404',
                'Content-Type': 'text/plain; charset=UTF-8'
                'Content-Length': '19'
                'Date': 'Sun, 52 Jan 2096 25:00:00 XST'
                'Expires': '-1'

            response.end 'Well, hello there.\n'
        server.listen 7357, ->
            middleman = new MiddleMan('http://localhost:7357')
            middleman.listen 7358, ->
                http.get { host: 'localhost', port: 7358, path: '/p/a/t/h' }, (response) ->
                    responseStatusCode = response.statusCode
                    responseHeaders = response.headers

        waitsFor (-> responseStatusCode?), 'response status code', 1000
        waitsFor (-> responseHeaders?), 'response headers', 1000

        runs ->
            expect(responseStatusCode).toEqual 404
            expect(responseHeaders).toEqual {
                'content-type': 'text/plain; charset=UTF-8'
                'content-length': '19'
                'date': 'Sun, 52 Jan 2096 25:00:00 XST'
                'expires': '-1'
                'connection': 'close'
            }

    it 'works over HTTPS', ->
        responseBody = undefined

        options =
            key: fs.readFileSync 'fixtures/keys/key.pem'
            cert: fs.readFileSync 'fixtures/keys/cert.pem'
        server = https.createServer options, (request, response) ->
            response.end 'Well, hello there.\n'
        server.listen 7357, ->
            middleman = new MiddleMan('https://localhost:7357')
            middleman.listen 7358, ->
                http.get { host: 'localhost', port: 7358, path: '/p/a/t/h' }, (response) ->
                    response.setEncoding 'utf8'
                    body = ''
                    response.on 'data', (chunk) -> body += chunk
                    response.on 'end', -> responseBody = body

        waitsFor (-> responseBody?), 'response', 1000
        runs ->
            expect(responseBody).toEqual 'Well, hello there.\n'
