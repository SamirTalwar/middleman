MiddleMan
=========

MiddleMan is a Node.js script written in order to figure out what was going on between a web server and a browser. Because the communication was over SSL, the connection couldn't be sniffed. MiddleMan will proxy the server in question and expose a non-encrypted HTTP server that you can connect to using your browser and observe with WireShark or any other sniffing tool.

Using MiddleMan
---------------

You will need [Node.js][] and [CoffeeScript][] to run MiddleMan. You can find instructions for installing them on their respective sites.

Once downloaded, you can run it easily:

    lib/middleman.coffee <URL to proxy>

For example, to proxy Google's encrypted domain:

    lib/middleman.coffee https://encrypted.google.com/

You can then connect to the server on `http://localhost:7769/`. A future version of MiddleMan will allow you to specify the port.

[Node.js]: http://nodejs.org/
[CoffeeScript]: http://jashkenas.github.com/coffee-script/
