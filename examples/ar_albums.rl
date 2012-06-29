; Based on:
; Example from http://snippets.dzone.com/posts/show/3097
; Copyright © Mike Wilson
; With permission from the author

(ruby-require "rubygems")
(ruby-require "active_record")

[ActiveRecord::Base logger= [Logger new STDERR]]
[ActiveRecord::Base colorize_logging= false]

[ActiveRecord::Base establish_connection (hash adapter: "sqlite3" dbfile: ":memory:")]

[ActiveRecord::Schema define &(fn()
  [self create_table 'albums &(fn (table)
    [table column 'title 'string]
    [table column 'performer 'string]
  )]

  [self create_table 'tracks &(fn (table)
    [table column 'album_id 'integer]
    [table column 'track_number 'integer]
    [table column 'title 'string]
  )]
)]

(let Album [Class new ActiveRecord::Base])
(class Album
  [self has_many 'tracks]
)

(let Track [Class new ActiveRecord::Base])
(class Track
  [self belongs_to 'album]
)

(let album [Album create (hash title: "Black and Blue" performer: "The Rolling Stones")])

[[album tracks] create (hash track_number: 1 title: "Hot Stuff")]
[[album tracks] create (hash track_number: 2 title: "Hand Of Fate")]
[[album tracks] create (hash track_number: 3 title: "Cherry Oh Baby ")]
[[album tracks] create (hash track_number: 4 title: "Memory Motel ")]
[[album tracks] create (hash track_number: 5 title: "Hey Negrita")]
[[album tracks] create (hash track_number: 6 title: "Fool To Cry")]
[[album tracks] create (hash track_number: 7 title: "Crazy Mama")]
[[album tracks] create (hash track_number: 8 title: "Melody (Inspiration By Billy Preston)")]

(let album [Album create (hash title: "Sticky Fingers"  performer: "The Rolling Stones")])
[[album tracks] create (hash track_number: 1 title: "Brown Sugar")]
[[album tracks] create (hash track_number: 2 title: "Sway")]
[[album tracks] create (hash track_number: 3 title: "Wild Horses")]
[[album tracks] create (hash track_number: 4 title: "Can't You Hear Me Knocking")]
[[album tracks] create (hash track_number: 5 title: "You Gotta Move")]
[[album tracks] create (hash track_number: 6 title: "Bitch")]
[[album tracks] create (hash track_number: 7 title: "I Got The Blues")]
[[album tracks] create (hash track_number: 8 title: "Sister Morphine")]
[[album tracks] create (hash track_number: 9 title: "Dead Flowers")]
[[album tracks] create (hash track_number: 10 title: "Moonlight Mile")]

(print [[[Album find 1] tracks] length])
(print [[[Album find 2] tracks] length])

(print [[Album find_by_title "Sticky Fingers"] title])
(print [[Track find_by_title "Fool To Cry"] album_id])
