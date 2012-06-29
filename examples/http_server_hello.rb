#!/usr/bin/ruby
require 'webrick'

# Configure the server
config = {:Port => 1337}

# Tell the class to make us a server object
server = WEBrick::HTTPServer.new(config)

# Tell server to call our Hello World handler
server.mount_proc("/hello") {|req,res|
        res.body = "<html><body><h3>Hello, world!</h3></body></html>"
        res["Content-Type"] = "text/html"
}

# Tell the server to go !
server.start
