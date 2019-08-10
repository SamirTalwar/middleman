const test = require("ava");
const fs = require("fs");
const http = require("http");
const https = require("https");
const net = require("net");
const path = require("path");
const request = require("supertest");
const {promisify} = require("util");
const MiddleMan = require("../src");

const fixturesDir = path.resolve(__dirname, "fixtures");
const tlsCertFile = path.join(fixturesDir, "keys", "cert.pem");
const tlsKeyFile = path.join(fixturesDir, "keys", "key.pem");

process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = 0;

test.afterEach.always(async t => {
  if (t.context.middleman != null) {
    await new Promise(resolve => {
      try {
        t.context.middleman.close(resolve);
      } catch (e) {
        reject(e);
      }
    });
  }

  if (t.context.server != null && t.context.server.listening) {
    await new Promise(resolve => {
      try {
        t.context.server.close(resolve);
      } catch (e) {
        reject(e);
      }
    });
  }
});

test("requesting the root directory", async t => {
  t.context.server = http.createServer((_request, response) => {
    response.end("Well, hello there.\n");
  });
  await promisify(t.context.server.listen.bind(t.context.server))();

  t.context.middleman = new MiddleMan(
    `http://localhost:${t.context.server.address().port}`,
  );

  await request(t.context.middleman.server)
    .get("/")
    .expect(200, "Well, hello there.\n");
  t.pass();
});

test("requesting the given path", async t => {
  let requestUrl;

  t.context.server = http.createServer(function(request, response) {
    requestUrl = request.url;
    response.end("Well, hello there.\n");
  });
  await promisify(t.context.server.listen.bind(t.context.server))();

  t.context.middleman = new MiddleMan(
    `http://localhost:${t.context.server.address().port}`,
  );

  await request(t.context.middleman.server)
    .get("/p/a/t/h?query=string#hash")
    .expect(200, "Well, hello there.\n");

  t.is(requestUrl, "/p/a/t/h?query=string");
});

test("handling POST requests with bodies", async t => {
  t.context.server = http.createServer((request, response) => {
    response.end("I'll get you, wabbit!");
  });
  await promisify(t.context.server.listen.bind(t.context.server))();

  t.context.middleman = new MiddleMan(
    `http://localhost:${t.context.server.address().port}`,
  );

  await request(t.context.middleman.server)
    .post("/p/a/t/h")
    .send("What's up, doc?")
    .expect(200, "I'll get you, wabbit!");

  t.pass();
});

test("forwarding headers from the client to the server", async t => {
  let requestHeaders;

  t.context.server = http.createServer((request, response) => {
    requestHeaders = request.headers;
    delete requestHeaders["user-agent"];
    response.end("Well, hello there.\n");
  });
  await promisify(t.context.server.listen.bind(t.context.server))();

  t.context.middleman = new MiddleMan(
    `http://localhost:${t.context.server.address().port}`,
  );

  await request(t.context.middleman.server)
    .get("/p/a/t/h")
    .set("Host", "www.example.com") // this will be thrown away
    .set("Content-Type", "text/plain")
    .set("Content-Length", "0")
    .set("Accept", "application/json")
    .expect(200, "Well, hello there.\n");

  t.deepEqual(requestHeaders, {
    host: "localhost", // ignores the value set above
    "content-type": "text/plain",
    "content-length": "0",
    accept: "application/json",
    "accept-encoding": "gzip, deflate",
    connection: "close",
  });
});

test("forwarding headers from the server to the client", async t => {
  t.context.server = http.createServer((_request, response) => {
    response.writeHead("404", {
      "Content-Type": "text/plain; charset=UTF-8",
      "Content-Length": "19",
      Date: "Sun, 52 Jan 2096 25:00:00 XST",
      Expires: "-1",
    });
    response.end("Well, hello there.\n");
  });
  await promisify(t.context.server.listen.bind(t.context.server))();

  t.context.middleman = new MiddleMan(
    `http://localhost:${t.context.server.address().port}`,
  );

  await request(t.context.middleman.server)
    .get("/p/a/t/h")
    .expect(404)
    .expect("Content-Type", "text/plain; charset=UTF-8")
    .expect("Content-Length", "19")
    .expect("Date", "Sun, 52 Jan 2096 25:00:00 XST")
    .expect("Expires", "-1")
    .expect("Connection", "close");
  t.pass();
});

test("supports an HTTPS server", async t => {
  const options = {
    key: await fs.promises.readFile(tlsKeyFile),
    cert: await fs.promises.readFile(tlsCertFile),
  };
  t.context.server = https.createServer(options, (_request, response) => {
    response.end("Well, hello there.\n");
  });
  await promisify(t.context.server.listen.bind(t.context.server))();

  t.context.middleman = new MiddleMan(
    `https://localhost:${t.context.server.address().port}`,
  );

  await request(t.context.middleman.server)
    .get("/p/a/t/h")
    .expect(200, "Well, hello there.\n");
  t.pass();
});

test("handles errors on the server", async t => {
  t.context.server = net.createServer(connection => {
    // badly implemented
    connection.destroy();
  });
  await promisify(t.context.server.listen.bind(t.context.server))();

  t.context.middleman = new MiddleMan(
    `http://localhost:${t.context.server.address().port}`,
  );

  await request(t.context.middleman.server)
    .get("/")
    .expect(502);
  t.pass();
});
