(let count 0)
[STDIN each & (fn (l) (set! count (+ count [l to_i])))]
(print count)
