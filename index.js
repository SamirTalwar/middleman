#!/usr/bin/env node

const http = require("http");
const https = require("https");
const url = require("url");

const PORT = 8080;

const REQUEST = {
  "http:": http.request,
  "https:": https.request,
};

class MiddleMan {
  constructor(proxiedUrl) {
    this.destination = url.parse(proxiedUrl);
    if (!(this.destination.protocol && this.destination.hostname)) {
      throw new Error(`Invalid destination: ${this.destination.href}`);
    }

    this.server = http.createServer((clientRequest, clientResponse) => {
      const options = {
        host: this.destination.hostname,
        port: this.destination.port,
        method: clientRequest.method,
        path: clientRequest.url,
        headers: {...clientRequest.headers, host: this.destination.hostname},
      };
      const request = REQUEST[this.destination.protocol];
      const serverRequest = request(options, serverResponse => {
        clientResponse.writeHead(
          serverResponse.statusCode,
          serverResponse.headers,
        );
        serverResponse.on("data", chunk => {
          clientResponse.write(chunk);
        });
        serverResponse.on("end", () => {
          clientResponse.end();
        });
      });
      clientRequest.on("data", chunk => {
        serverRequest.write(chunk);
      });
      return clientRequest.on("end", () => {
        serverRequest.end();
      });
    });
  }

  listen(...args) {
    return this.server.listen(...args);
  }

  close(callback) {
    this.server.on("close", callback);
    return this.server.close();
  }
}

const main = () => {
  if (process.argv.length < 3) {
    process.stderr.write(`Usage: ${process.argv[1]} URL [PORT]\n`);
    process.exit(2);
  }

  const port = process.argv[3] ? parseInt(process.argv[3]) : PORT;
  const middleman = new MiddleMan(process.argv[2]);
  middleman.listen(port);
};

if (module === require.main) {
  main();
}
