(print
  (case 2
    1 (+ "on" "e")
    2 (+ "tw" "o")
      (+ "neith" "er")
  )
)
(print
  (
    (fn (x)
      (case x
        1 (+ "ON" "E")
        2 (+ "TW" "O")
          (+ "NEITH" "ER")
      )
    )
    2
  )
)
