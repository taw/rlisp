;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; The most basis definitions
(letmacro defmacro
  (fn (name args . body)
    `(letmacro ,name (fn ,args ,@body))))

(defmacro defun (name . body)
  `(let ,name (fn ,@body)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; generate an unique symbol - useful for macros
(defun gensym ()
  (ruby-eval "$gensym||=0; $gensym+=1; ('#:G' + $gensym.to_s).to_sym"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Logic special forms
(defmacro and args
  (if (empty? args)
    `true
    (do
      (let tmp (gensym))
      `(do
        (let ,tmp ,(hd args))
        (if ,tmp
          (and ,@(tl args))
          ,tmp)))))
(defmacro or args
  (if (empty? args)
    `false
    (do
      (let tmp (gensym))
      `(do
        (let ,tmp ,(hd args))
        (if ,tmp
          ,tmp
          (or ,@(tl args)))))))

(defun not (a) (if a false true))

(defmacro bool-and args
  (if (empty? args)
    `true
    (if [[args size] == 1]
      (hd args)
      `(if ,(hd args)
        (bool-and ,@(tl args))
        false))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; function which simply alias methods
(defun divide (a b) [a divide b])
(defun > (a b) [a > b])
(defun >= (a b) [a >= b])
(defun < (a b) [a < b])
(defun <= (a b) [a <= b])
(defun eql? (a b) [a eql? b])
(defun size (obj) [obj size])
(defun empty? (obj) [obj empty?])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Ugly optimization
(defun == (a b) [a == b])
(defmacro == (a b) `[,a == ,b])
(let eq? ==)
(defmacro eq? (a b) `[,a == ,b])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Lisp-compatible aliases
(defmacro lambda args
  `(fn ,@args))
(let car hd)
(let cdr tl)
(let length size)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; These should really be plain functions, but for
; performance reasons they're macros
;
; It's really ugly and should be fixed in future versions

(defmacro + (a . b)
  (if [b empty?]
  a
  `[,a + (+ ,@b)]))

(defmacro * (a . b)
  (if [b empty?]
  a
  `[,a * (* ,@b)]))

(defmacro - (a . b)
  (if [b empty?]
    `[,a -@]
    (if [[b size] == 1]
      `[,a - ,(hd b)]
      `(- [,a - ,(hd b)] ,@(tl b)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Basic List functions
(defun map (fun lst) [lst map & fun])
(defun list args args)
(defun flatten1 (lst) [lst inject () & (fn (a b) (+ a b))])

; Return ith element
(defun nth (lst i) [lst get i])
; Skip first i elements and return the rest
(defun ntl (lst i)
  (if (< i (size lst))
    [lst last (- (size lst) i)]
    ()))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Higher-level Syntax forms - cons
; Usage:
; (cond condition_0 result_0 ... condition_n result_n default)
; or:
; (cond condition_0 result_0 ... condition_n result_n) ; default=nil
(defmacro cond args
  (if (>= (size args) 2)
    `(if ,(nth args 0)
      ,(nth args 1)
      (cond ,@(ntl args 2)))
    (if (eq? (size args) 1)
      (nth args 0)
      nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Higher-level Syntax forms - case
; Like Ruby case/when:
; (case var pattern_0 result_0 ... pattern_n result_n default)
; (case var pattern_0 result_0 ... pattern_n result_n) ; default=nil

(defmacro case-2 (tmp . cases)
  (if (>= (size cases) 2)
    `(if [,(nth cases 0) === ,tmp]
      ,(nth cases 1)
      (case-2 ,tmp ,@(ntl cases 2)))
    (if (eq? (size cases) 1)
       (nth cases 0)
       nil)))

(defmacro case (var . cases)
  (let tmp (gensym))
  `(do
    (let ,tmp ,var)
    (case-2 ,tmp ,@cases)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Higher-level Syntax forms - match
; Pattern matching
(defmacro match-3 (tmp pattern)
  (if [pattern is_a? Array]
  ; zero-length list
    (if [pattern == ()] 
  ; 'foo
      `[,tmp == ,pattern]
      (if [(hd pattern) == 'quote]
        `[,tmp == ',(nth pattern 1)]
         (if [[pattern get -2] == '.]
          ; lists ending in dotted pair
            `(bool-and
               [,tmp is_a? Array]
               [[,tmp size] >= ,[[pattern size] - 2]]
               ,@[[Range new 0 [[pattern size] - 3]] map & (fn (i)
                 (let tmpi (gensym))
                 `(do
                    (let ,tmpi [,tmp get ,i])
                    (match-3 ,tmpi ,(nth pattern i))))]
               ,(do
                  (let tmprest (gensym))
                  `(do
                     (let ,tmprest (ntl ,tmp ,[[pattern size] - 2]))
                     (match-3 ,tmprest ,[pattern get -1]))))
          ; normal lists
            `(bool-and
               [,tmp is_a? Array]
               [[,tmp size] == ,[pattern size]]
               ,@[[Range new 0 [[pattern size] - 1]] map & (fn (i)
                 (let tmpi (gensym))
                 `(do
                    (let ,tmpi [,tmp get ,i])
                    (match-3 ,tmpi ,(nth pattern i))))]))))
    (if [pattern is_a? Symbol]
      `(do (let ,pattern ,tmp) true)
      `[,tmp == ,pattern])))

(defmacro match-2 (tmp . cases)
  (if [cases empty?]
    `nil
    (if (== [cases size] 1)
      (hd cases)
      `(if (match-3 ,tmp ,(nth cases 0))
        ,(nth cases 1)
        (match-2 ,tmp ,@(ntl cases 2)))))
)

(defmacro match (val . cases)
  (let tmp (gensym))
  `(do
    (let ,tmp ,val)
    (match-2 ,tmp ,@cases)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Literal syntax for hash tables, interpolated strings
; and regular expressions

(let hash-key
(ruby-eval "lambda{|x| xs=x.to_s; xs[0,xs.size-1].to_sym}"))

(defmacro hash-add-elements (h args)
  (match args
   ()    `(do)
   (x)     `[,h default= ,x]
   (k '=> v) `[,h set ,k ,v]
   (k '=> v . r) `(do [,h set ,k ,v]
          (hash-add-elements ,h ,r)
         )
   (k v)   `[,h set ',(hash-key k) ,v]

   (k v . r) `(do [,h set ',(hash-key k) ,v]
          (hash-add-elements ,h ,r)
         )
    z     (raise SyntaxError [`(hash-add-elements ,h ,args) inspect_lisp])))

(defmacro hash args
  (let tmp (gensym))
   `(do
    (let ,tmp [Hash new])
    (hash-add-elements ,tmp ,args)
    ,tmp))

(defun str args
   [[args map & (fn (x) [x to_s_lisp])] join])

(defun rx (pattern)
  [Regexp new pattern])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OO constructs
(defmacro class (name . body)
  `[,name instance_eval & (fn ()
    ,@body)])

(defmacro method (name args . body)
  `[self
    define_method ',name & (fn ,args ,@body)])

(defmacro attr-accessor args `[self attr_accessor ,@args])
(defmacro attr-reader args `[self attr_reader ,@args])
(defmacro attr-writer args `[self attr_writer ,@args])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Create a local lexical scope

(defmacro local body
  `((fn () ,@body)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Syntax for ranges

(defun .. (a b) [Range new a b])
(defun ... (a b) [Range new a b true])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Require Ruby library

(defun ruby-require (lib) (ruby-eval (+ "require '" lib "'")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Regexp macros
;(defmacro rx-results (m . args)
;  (let res '(do))
;  [args each_with_index & (fn (x i)
;    [res push `(let ,x [,m get ,[i + 1]])]
;  )]
;  [res push 'true]
;  res
;)

(defmacro rx-results (m . args)
  (let res '(do))
  [args each_with_index & (fn (x i)
    (match x
      ('f v) [res push `(let ,v [[,m get ,[i + 1]] to_f])]
      ('i v) [res push `(let ,v [[,m get ,[i + 1]] to_i])]
             [res push `(let ,x [,m get ,[i + 1]])])
  )]
  [res push 'true]
  res
)

(defmacro rx-match (s rx . args)
  (let tmp (gensym))
 `(do
    (let ,tmp [,s match ,rx])
    (if ,tmp
      (rx-results ,tmp ,@args)
      false)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Useful as building blocks of many DSLs

(defmacro sendq (obj meth . args)
  `(send ,obj ',meth ,@args))

(defmacro cmd options
  (let hash_index -1)
  [options each_with_index &(fn (x i)
    (cond
      (and [hash_index == -1] [x is_a? Symbol] [[x to_s] =~ /:\Z/]) (set! hash_index i)
      (and [hash_index == -1] [x == '=>]) (set! hash_index [i - 1]))
  )]
  (if (== hash_index -1)
    (sendq options)
    (do
      (let normal_args [options get [0 ... hash_index]])
      (let hash_args [options get [hash_index .. -1]])
      `(sendq ,@normal_args (hash ,@hash_args))))
)

(defmacro cmds (recv . args)
  (let tmp (gensym))
  (let args-expanded [args map &(fn (a)
    `(cmd ,recv ,@a)
  )])
  `(do ,@args-expanded)
)
