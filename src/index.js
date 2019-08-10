const http = require("http");
const https = require("https");
const url = require("url");

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
      serverRequest.on("error", error => {
        clientResponse.writeHead(502);
        clientResponse.write(http.STATUS_CODES[502]);
        clientResponse.write("\n\n");
        clientResponse.write(error.message);
        clientResponse.end();
      });
      clientRequest.on("data", chunk => {
        serverRequest.write(chunk);
      });
      clientRequest.on("end", () => {
        serverRequest.end();
      });
    });
  }

  listen(...args) {
    return this.server.listen(...args);
  }

  close(callback) {
    return this.server.close(callback);
  }
}

module.exports = MiddleMan;
module.exports.default = MiddleMan;
