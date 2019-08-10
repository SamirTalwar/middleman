#!/usr/bin/env node

const MiddleMan = require("./src");

const PORT = 8080;

if (process.argv.length < 3) {
  process.stderr.write(`Usage: ${process.argv[1]} URL [PORT]\n`);
  process.exit(2);
}

const port = process.argv[3] ? parseInt(process.argv[3]) : PORT;
const middleman = new MiddleMan(process.argv[2]);
middleman.listen(port);
