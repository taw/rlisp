; I think this is a wrong way to do it. Check html.rl instead

(ruby-eval
"class ::String
  def html_escape
    gsub(/&/,'&amp;').gsub(/</,'&lt;').gsub(/>/,'&gt;')
  end
end")

(defun html-quote (arg)
  (if [arg is_a? Array]
    (if (== (hd arg) 'html-raw)
      [(tl arg) join]
      [[arg map & html-quote] join]
    )
    [arg html_escape]
  )
)

(defun html-raw (arg)
  (list 'html-raw arg)
)

(defun print-html (arg)
   (print (html-quote arg))
)

(defun list args
    args
)

(defmacro define-tag (tag)
  `(defmacro ,tag children
     `(html-raw
       (list
         ,(str "<" tag ">")
         (html-quote (list ,',@children))
         ,(str "</" tag ">")
       )
    )
  )
)

(define-tag html)
(define-tag head)
(define-tag body)
(define-tag title)
(define-tag p)
(define-tag h3)
(define-tag a)

(print-html
  (html
    (head
      (title "<<< Ruby & Lisp united >>>")
    )
    (body
      (p "<>& are safe by default."
         (html-raw "Unsafe only when explicitely requested &excl;")
      )
    )
  )
)
