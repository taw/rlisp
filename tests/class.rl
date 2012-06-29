(let Point [Class new])
[Point attr_accessor 'x]
[Point attr_accessor 'y]
[Point define_method 'to_s
  (fn () "<#{@x},#{@y}>")
]
(let a [Point new])
[a x= 2]
[a y= 5]
(print a)
