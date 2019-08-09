# MiddleMan

A very simple HTTP proxy that can proxy an HTTPS server.

## Using MiddleMan

You will need [Node.js][] to run MiddleMan.

Once cloned, you can run it easily:

    ./index.js <URL to proxy>

For example, to proxy Google's encrypted domain:

    ./index.js https://encrypted.google.com/

You can then connect to the server on [http://localhost:8080/]().

You can optionally specify a port. The following command runs the proxy on port 5000:

    ./index.js https://encrypted.google.com/ 5000

[node.js]: http://nodejs.org/
