(ruby-require "opengl")
(ruby-require "glut")

(defun disp ()
  [GL Clear GL::COLOR_BUFFER_BIT]
  [GL Begin GL::TRIANGLES]
    [GL Color 0.0 0.0 1.0]
    [GL Vertex 0 0]
    [GL Color 0.0 1.0 0.0]
    [GL Vertex 200 200]
    [GL Color 1.0 0.0 0.0]
    [GL Vertex 20 200]
  [GL End]
  [GL Flush]
)

(defun reshape (w h)
  [GL Viewport 0 0 w h]
  [GL MatrixMode GL::PROJECTION]
  [GL LoadIdentity]
  [GL Ortho 0 w 0 h -1 1]
  [GL Scale 1 -1 1]
  [GL Translate 0 (- h) 0]
)

[GLUT Init]
(let a [GLUT CreateWindow "single triangle"])
[GLUT DisplayFunc disp]
[GLUT ReshapeFunc reshape]
[GLUT MainLoop]
