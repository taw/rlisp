; Based on:
; Example from http://snippets.dzone.com/posts/show/3097
; Copyright © Mike Wilson
; With permission from the author

(require "active_record.rl")

[ActiveRecord::Base logger= [Logger new STDERR]]
[ActiveRecord::Base colorize_logging= false]

(active-record-establish-connection adapter: "sqlite3" dbfile: ":memory:")

(active-record-schema-define
  (create-table albums
    (title string)
    (performer string))
  (create-table tracks
    (album_id integer)
    (track_number integer)
    (title string))
)

(define-active-record-class Album
  (has_many 'tracks)
)

(define-active-record-class Track
  (belongs_to 'album)
)

(let album (cmd Album create title: "Black and Blue" performer: "The Rolling Stones"))

(cmds [album tracks]
  (create track_number: 1 title: "Hot Stuff")
  (create track_number: 2 title: "Hand Of Fate")
  (create track_number: 3 title: "Cherry Oh Baby ")
  (create track_number: 4 title: "Memory Motel ")
  (create track_number: 5 title: "Hey Negrita")
  (create track_number: 6 title: "Fool To Cry")
  (create track_number: 7 title: "Crazy Mama")
  (create track_number: 8 title: "Melody (Inspiration By Billy Preston)"))

(let album (cmd Album create title: "Sticky Fingers"  performer: "The Rolling Stones"))
(cmds [album tracks]
  (create track_number: 1 title: "Brown Sugar")
  (create track_number: 2 title: "Sway")
  (create track_number: 3 title: "Wild Horses")
  (create track_number: 4 title: "Can't You Hear Me Knocking")
  (create track_number: 5 title: "You Gotta Move")
  (create track_number: 6 title: "Bitch")
  (create track_number: 7 title: "I Got The Blues")
  (create track_number: 8 title: "Sister Morphine")
  (create track_number: 9 title: "Dead Flowers")
  (create track_number: 10 title: "Moonlight Mile"))

(print [[[Album find 1] tracks] length])
(print [[[Album find 2] tracks] length])

(print [[Album find_by_title "Sticky Fingers"] title])
(print [[Track find_by_title "Fool To Cry"] album_id])
