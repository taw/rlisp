(let ht [Hash new])
[ht set 'a 2]
[ht set 'b 4]
[ht set 'a 6]
(print (+ [ht get 'a] [ht get 'b]))
(print ht)
