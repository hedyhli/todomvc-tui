# Go Vaxis

Super great that modern terminal features are built-in, such as blinking
beam-style cursors, and the Kitty keyboard protocols.

The use of overlay-able windows as part of the architecture is similar in some
ways to gocui, but Vaxis appears to make use more of Elm's Architecture than
tview's or gocui's alternative methods of dealing with redraws and event-loops.

## Implementation notes

`model.drawRoot()` creates many new windows for the entire TUI when called. Does
this mean duplicated windows in the same positions are laid on top of each
other when rendering? It feels like external overhead as `drawRoot` is called
more and more times, if that's the case.

This is necessary though, however, because the windows' dimensions depends on
the terminal dimensions, which changes after resize events. Vaxis does not seem
to provide a way to resize windows and so new windows must be created. Windows
can neither be destroyed, it seems.
