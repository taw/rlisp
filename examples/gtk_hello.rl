(ruby-require "gtk2")

(let w [Gtk::Window new "RLisp Gtk Hello World"])
[w border_width= 10]

(let v [Gtk::VBox new])

(let l [Gtk::Label new "Hello, World"])

(let b [Gtk::Button new "Quit"])

[v pack_start l]
[v pack_start b]

[b signal_connect "clicked" & (fn ()
  (print "Hello, world!")
  [Gtk main_quit]
)]

[w add v]
[w show_all]
    
[Gtk main]
