# V `term.ui`

I was oblivious of the historical drama concerning the V community when starting
out, and while working on this implementation I felt that it was quite
delightful to use. It's a pity a language like V with such potential had such a
rough start, and I hope to see more amazing things people build with it, and how
it evolves in the future, but I will probably not make V my go-to language for
systems and general purpose programming (or advocate for its use). V scripting
is quite interesting, as with Nim for scripting, but unfortunately only things
like POSIX and python can be expected to to be available on most systems. That
said, I am still very much interested in experiementing with both V scripting
and the V programming language for hobby projects.

I'd also like to note that this is the only implementation, so far, that makes
use of only its standard library. It's probably possible to use curses in
Python, or other low-level terminal abstractions in other languages without
getting too laborious, but I was surprised to find that V has a full-fledged
solution to build fully interactive TUI apps built-in.
