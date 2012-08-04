(defun sql-field (arg)
  (match arg
    ('count fld) (str "COUNT(" fld ")")
    ('sum fld)   (str "SUM("   fld ")")
    ('avg fld)   (str "AVG("   fld ")")
    ('max fld)   (str "MAX("   fld ")")
    ('min fld)   (str "MIN("   fld ")")
    [arg to_s]))

(defun sql-fields (args)
  (case args
    '*     "*"
    Symbol [args to_s]
    Array  [(map sql-field args) join ", "]))

(defun sql-table (arg)
  (match arg
    (tbl 'as als) (str tbl " AS " als)
    [arg to_s]))

(defun sql-tables (args)
  (case args
    Symbol [args to_s]
    Array  [(map sql-table args) join ", "]))

(defun sql-where-conds (args)
  (match args
    (fld '= val)  (list (str fld "=%") val)
    (fld '== val) (list (str fld "=%") val)
    (fld '!= val) (list (str fld "!=%") val)
    (fld '>  val) (list (str fld ">%") val)
    (fld '>= val) (list (str fld ">=%") val)
    (fld '<  val) (list (str fld "<%") val)
    (fld '<= val) (list (str fld "<=%") val)
    ('and . conds) (do
                     (let pconds (map sql-where-conds conds))
                     (let txt [(map hd pconds) join " AND "])
                     (let vals (flatten1 (map tl pconds)))
                     (cons (+ "(" txt ")") vals))
    ('or . conds) (do
                     (let pconds (map sql-where-conds conds))
                     (let txt [(map hd pconds) join " OR "])
                     (let vals (flatten1 (map tl pconds)))
                     (cons (+ "(" txt ")") vals))
    (raise SyntaxError [(cons 'sql-where-conds args) inspect_lisp])))

(defun sql-conds (args)
  (match args
    ()  (list "")
    ('where wconds)
                    (do
                      (let pconds (sql-where-conds wconds))
                      (cons
                        (+ " WHERE " (hd pconds))
                        (tl pconds)))
    ('order-by ('- fld)) (list (str " ORDER BY -" fld))
    ('order-by fld)      (list (str " ORDER BY " fld))
    ('group-by fld)      (list (str " GROUP BY " fld))
    ('limit num)         (list (str " LIMIT " num))
    ('offset num)        (list (str " OFFSET " num))
    (a b c . rest)
                    (do
                      (let res-a (sql-conds (list a b)))
                      (let res-b (sql-conds (cons c rest)))
                      (cons
                        (+ (hd res-a) (hd res-b))
                        (+ (tl res-a) (tl res-b))))
    (raise SyntaxError [(cons 'sql-conds args) inspect_lisp])))

(defmacro sql args
  (match args
    ('select fields 'from tables . conds)
      (do
        (let conds (sql-conds conds))
       `(sql-run
          ,(+ "SELECT " (sql-fields fields)
             " FROM " (sql-tables tables)
             (hd conds))
           ,@(tl conds)))
    (raise SyntaxError [(cons 'sql args) inspect_lisp])))
