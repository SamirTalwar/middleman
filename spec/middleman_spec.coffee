http = require 'http'
Middleman = require '../lib/middleman'

describe 'proxying a server', ->
    it 'requests the root directory', ->
        responseBody = undefined

        http.createServer((request, response) ->
            response.end 'Well, hello there.\n'
        ).listen 7357, ->
            new Middleman('http://localhost:7357').listen 7358, ->
                http.get { host: 'localhost', port: 7358, path: '/' }, (response) ->
                    response.setEncoding 'utf8'
                    body = ''
                    response.on 'data', (chunk) -> body += chunk
                    response.on 'end', -> responseBody = body

        waitsFor (-> responseBody?), 'response', 1000
        runs -> expect(responseBody).toEqual 'Well, hello there.\n'
