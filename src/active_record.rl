(ruby-require "rubygems")
(ruby-require "active_record")

(defmacro active-record-establish-connection options
  `(cmd ActiveRecord::Base establish_connection ,@options))

(defmacro active-record-schema-define defs
  (let expanded-defs [defs map & (fn (d) (match d
    ('create-table . args) `(schema-define-create-table ,@args)
    (raise "Unrecognized statement in schema definition: #{d}")
  ))])
  `[ActiveRecord::Schema define &(fn() ,@expanded-defs)]
)

(defmacro schema-define-create-table (table-name . entries)
  (let tmp (gensym))
  (let expanded-entries [entries map &(fn (entry)
    (let name [entry get 0])
    (let type [entry get 1])
    `[,tmp column ',name ',type])])
  `[self create_table ',table-name &(fn (,tmp) ,@expanded-entries)]
)

(defmacro define-active-record-class (class-name . defs)
  (let expanded-defs [defs map &(fn (d) (match d
    (has_many . args)    `[self has_many ,@args]
    (has_one . args)     `[self has_one ,@args]
    (belongs_to . args)  `[self belongs_to ,@args]
    (has_and_belongs_to_many . args)  `[self has_and_belongs_to_many ,@args]
    _ d
  ))])
  `(do
    (let ,class-name [Class new ActiveRecord::Base])
    (class ,class-name
      ,@expanded-defs
    )
  )
)
