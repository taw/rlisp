(let a '(1 2 3))
[a each &
  (fn (i)
    (print i)
  )
]
