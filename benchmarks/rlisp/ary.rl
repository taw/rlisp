(let n [(or [ARGV shift] 1) to_i])
(let x [Array new n])
(let y [Array new n 0])
[n times & (fn (i)
    [x set i (+ i 1)]
)]

[1000 times & (fn (j)
    [(- n 1) step 0 -1 & (fn (i)
        [y set i (+ [y get i] [x get i])]
    )]
)]

(print [y first] " " [y last])
