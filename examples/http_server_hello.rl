; By default WEBrick captures ^C, so kill -9 it :-)

(ruby-require "webrick")

; Create server object
(let server [WEBrick::HTTPServer new (hash Port: 1337)])

; Tell server to call our Hello World handler
[server mount_proc "/hello"
  (fn (req res)
    [res body= "<html><body><h3>Hello, world!</h3></body></html>"]
    [res []= "Content-Type" "text/html"]
  )
]

; Tell the server to go !
[server start]
