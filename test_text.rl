(require "rlunit.rl")

(defun parse-ip (s)
  (let m [s match /\A(\d+)\.(\d+)\.(\d+)\.(\d+)\Z/])
  (if m
    (do
      (let a [[m get 1] to_i])
      (let b [[m get 2] to_i])
      (let c [[m get 3] to_i])
      (let d [[m get 4] to_i])
      (list a b c d))
    (raise "Cannot parse IP"))
)

(defun parse-ip-2 (s)
  (if (rx-match s /\A(\d+)\.(\d+)\.(\d+)\.(\d+)\Z/ a b c d)
      (list [a to_i] [b to_i] [c to_i] [d to_i])
    (raise "Cannot parse IP"))
)

(defun parse-ip-3 (s)
  (if (rx-match s /\A(\d+)\.(\d+)\.(\d+)\.(\d+)\Z/ (i a) (i b) (i c) (i d))
      (list a b c d)
    (raise "Cannot parse IP"))
)

(test-suite Text_Processing
  (test parse-ip
    (assert (parse-ip "1.2.3.4") == '(1 2 3 4))
    (assert (parse-ip "64.233.183.104") == '(64 233 183 104)))
  (test parse-ip-2
    (assert (parse-ip-2 "1.2.3.4") == '(1 2 3 4))
    (assert (parse-ip-2 "64.233.183.104") == '(64 233 183 104)))
  (test parse-ip-3
    (assert (parse-ip-3 "1.2.3.4") == '(1 2 3 4))
    (assert (parse-ip-3 "64.233.183.104") == '(64 233 183 104)))
)
