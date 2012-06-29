; By default WEBrick captures ^C, so kill -9 it :-)

; Define a macro for HTML mounts
(defmacro def-server-html-mount args
  `[,(nth args 0) mount_proc ,(nth args 1)
     (fn (req res)
       [res []= "Content-Type" "text/html"]
       [res body= (do ,@(ntl args 2))]
       (print res)
     )
  ]
)

; Define a macro for HTML tag function
(defmacro def-html-tag (tagname)
  `(defun ,tagname args
    (+
      "<"  [',tagname to_s] ">"
      [args join]
      "</" [',tagname to_s] ">"
    )
  )
)

(ruby-require "webrick")

; Configure the server
(let config [Hash new])
[config set 'Port 1337]
; Tell the class to make us a server object
(let server [WEBrick::HTTPServer new (hash Port: 1337)])

; Tell server to call our Hello World handler
(def-server-html-mount server "/hello" 
  "<html><body><h3>Hello, world!</h3></body></html>"
)

; Tell server to call our Hello World handler
(def-html-tag html)
(def-html-tag body)
(def-html-tag h3)

(def-server-html-mount server "/hello2" 
  (html (body (h3 "Macros Greet you")))
)

; Tell the server to go !
[server start]
