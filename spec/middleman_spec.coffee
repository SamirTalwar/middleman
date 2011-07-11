http = require 'http'
Middleman = require '../lib/middleman'

describe 'proxying a server', ->
    it 'requests the root directory', ->
        responseBody = undefined

        middleman = undefined
        server = http.createServer (request, response) ->
            response.end 'Well, hello there.\n'
        server.listen 7357, ->
            middleman = new Middleman('http://localhost:7357')
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
            middleman = new Middleman('http://localhost:7357')
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
