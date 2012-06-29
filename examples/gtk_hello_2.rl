(ruby-require "gtk2")

; Definition of Gtk DSL
(defun gtk-attrs (widget args)
  (let tmp (gensym))
  (defun parse-args (args)
    (match args
      ('id '=> var . rest)
          (cons `(let ,var ,tmp) (parse-args rest))
      ('signal sig '=> handler . rest) 
          (cons `[,tmp signal_connect ,sig & ,handler] (parse-args rest))
      (prop '=> val . rest)
          (cons `[,tmp ,["#{prop}=" to_sym] ,val] (parse-args rest))
      (child . rest)
          (cons `[,tmp add ,child] (parse-args rest))
      ()
          ()
      x
          (raise "Don't know what to do with: #{args}")))
  (let ops (parse-args args))
  `(do
    (let ,tmp ,widget)
    ,@ops
    ,tmp)
)

(defmacro gtk (widget constr_args . attributes)
  (gtk-attrs `[,["Gtk::#{widget}" to_sym] new ,@constr_args] attributes))

; The program
(gtk Window ("RLisp Gtk Hello World")
  id => w
  border_width => 10
  (gtk VBox ()
    (gtk Label ("Hello, World"))
    (gtk Button ("Quit")
      signal "clicked" => (fn ()
        (print "Hello, world!")
        [Gtk main_quit]))
  )
)

[w show_all]
    
[Gtk main]
