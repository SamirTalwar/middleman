fs = require 'fs'
http = require 'http'
https = require 'https'
MiddleMan = require '../lib/middleman'

describe 'proxying a server', ->
    it 'requests the root directory', ->
        responseBody = undefined

        middleman = undefined
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
            try
                expect(responseBody).toEqual 'Well, hello there.\n'
            finally
                server.close()
                middleman.close()

    it 'requests the given path', ->
        requestUrl = undefined
        responseBody = undefined

        middleman = undefined
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
            try
                expect(requestUrl).toEqual '/p/a/t/h?query=string#hash'
                expect(responseBody).toEqual 'Well, hello there.\n'
            finally
                server.close()
                middleman.close()

    it 'handles POST requests with bodies', ->
        requestMethod = undefined
        requestBody = undefined
        responseBody = undefined

        middleman = undefined
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
            try
                expect(requestMethod).toEqual 'POST'
                expect(requestBody).toEqual 'What\'s up, doc?'
                expect(responseBody).toEqual 'I\'ll get you, wabbit!'
            finally
                server.close()
                middleman.close()

    it 'forwards headers', ->
        requestHeaders = undefined
        responseBody = undefined

        middleman = undefined
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
                        'host': 'www.example.com'
                        'content-type': 'text/plain'
                        'content-length': '0'
                        'accept': 'application/json'

                http.get options, (response) ->
                    response.setEncoding 'utf8'
                    body = ''
                    response.on 'data', (chunk) -> body += chunk
                    response.on 'end', -> responseBody = body

        waitsFor (-> requestHeaders?), 'request URL', 1000
        waitsFor (-> responseBody?), 'response', 1000

        runs ->
            try
                expect(requestHeaders).toEqual {
                    'host': 'www.example.com'
                    'content-type': 'text/plain'
                    'content-length': '0'
                    'accept': 'application/json'
                    'connection': 'close'
                }
                expect(responseBody).toEqual 'Well, hello there.\n'
            finally
                server.close()
                middleman.close()

    it 'works over HTTPS', ->
        responseBody = undefined

        middleman = undefined
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
            try
                expect(responseBody).toEqual 'Well, hello there.\n'
            finally
                server.close()
                middleman.close()
