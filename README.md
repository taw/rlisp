rlisp
=====

RLisp is a Lisp dialect naturally embedded in Ruby

Usage
=====

Tests in tests/ and examples in examples/ and microexamples/ are about the only documentation.
You can also check rlisp-related posts on my blog at http://t-a-w.blogspot.co.uk/search/label/rlisp
but they might not necessarily be up to date.

For interactive environment use:
$ ./src/rlisp.rb
rlisp> (+ 2 2)
4
rlisp> ^D
$

For running things use:
$ ./src/rlisp.rb microexamples/fib.rl
(1 2 3 5 8)
$

You can write RLisp one-liners with -e:
$ ./src/rlisp.rb -e '(print (+ 2 40))'
42
$

or with -i -e to print all evaluated expressions:
$ ./src/rlisp.rb -ie '(+ 2 40)'
42
$

Enjoy :-)

Sources
=======

Except for benchmarks/ruby/, the code was written
by Tomasz Wegrzanowski <Tomasz.Wegrzanowski@gmail.com>

The code is available under MIT-like Licence (see doc/COPYING).
