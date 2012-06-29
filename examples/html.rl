(let html-escapes-table (hash
  "&" => "&amp;"
  ">" => "&gt;"
  "<" => "&lt;"
  "\"" => "&quot;"
  "'" => "&apos;"
))

(class String
  (method html_escape ()
    [self gsub /([&<>"'])/ & (fn (c) [html-escapes-table get c])]
  )
)

; Tags which should not get a closing tag
; (they should also have no content, but that's not enforced yet)
(let html-omit-closing-tag (hash
  br:  true
  img: true
  false
))

(defun html-to-s (arg)
  (match arg
    ('raw string) string
    (tag attrs . body)
        (+
          "<#{tag}#{[[attrs map & (fn (kv) " #{[kv get 0]}='#{[[kv get 1] html_escape]}'")] join]}>"
          [[body map & html-to-s] join]
          (if [html-omit-closing-tag get tag] "" "</#{tag}>")
        )
    obj [obj html_escape]
  )
)

(defun print-html (arg) (print (html-to-s arg)))

(defmacro deftags tags
  (cons 'do
    (map
    (fn (tag)
      `(defmacro ,tag (attrs . body) `(list ',tag (hash ,',@attrs) ,',@body)))
    tags))
)
(defun raw (cnt) `(raw ,cnt))

; Just a few tags, not a complete list
(deftags html head body title img p h1 h2 h3 h4 h5 h6 ul ol li table tr td th)

(print-html (html ()
  (head ()
    (title () "This is an awesome & very educational example")
  )
  (body ()
    (img (src: "foo.png"))
    (p () (raw "Raw html is possible, if you ever need it &excl;"))
  )
))
