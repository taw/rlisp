; This isn't elegant at all
; Just a quick hack showing how to use non-copying structural
; iteration over list

(let IArray [Class new])
[IArray attr_accessor 'lst]
[IArray attr_accessor 'ofs]
[IArray define_method 'initialize
  (fn (lst ofs)
    [self ofs= ofs]
    [self lst= lst]
  )
]
[IArray define_method 'car
  (fn ()
    (if [self empty?]
      nil
      [[self lst] get [self ofs]]
    )
  )
]
[IArray define_method 'cdr
  (fn ()
    (if [self empty?]
      ()
      [IArray new [self lst] (+ [self ofs] 1)]
    )
  )
]
[IArray define_method 'length
  (lambda ()
    (- [[self lst] length] [self ofs])
  )
]
[IArray define_method 'to_s
  (lambda ()
    (+ "<" [[self lst] to_s_lisp] " @ " [[self ofs] to_s] ">")
  )
]
[IArray define_method 'empty?
  (lambda ()
    (eq? [self length] 0)
  )
]

; Functions like car/cdr/cons are not methods or generics.
; Maybe they should be.
(defun i-car (lst)
  (cond
    [lst is_a? Array] (car lst)
    [lst is_a? IArray] [lst car]
    (ruby-eval "raise 'i-car called on non-Array/IArray'")
  )
)

(defun i-cdr (lst)
  (cond
    [lst is_a? Array] [IArray new lst 1]
    [lst is_a? IArray] [lst cdr]
    (ruby-eval "raise 'i-cdr called on non-Array/IArray'")
  )
)

(defun empty? (lst)
  (eq? [lst size] 0)
)

(defun i-empty? (lst)
  (cond
    [lst is_a? Array] [lst empty?]
    [lst is_a? IArray] [lst empty?]
    (ruby-eval "raise 'i-empty? called on non-Array/IArray'")
  )
)

(defun sum (lst)
  (if (empty? lst)
    0
    (+ (car lst) (sum (cdr lst)))
  )
)

(defun i-sum (lst)
  (if (i-empty? lst)
    0
    (+ (i-car lst) (i-sum (i-cdr lst)))
  )
)

(let lst [Array new 100 & (fn (i) i)])
(print (sum lst))
(print (i-sum lst))
