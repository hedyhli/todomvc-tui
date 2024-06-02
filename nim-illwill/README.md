# Nim Illwill

It does not seem possible to make use of the terminal cursor directly when
working with the input widget, so I painted the cursor manually instead, as with
what seems to be done in illwill-widgets.

Only illwill the library is used in this implementation, no widget libraries. It
makes this implementation very similar to V-lang's, where I have to draw all the
boxes and text myself to make the widgets.

One difference of this to V's is that I have to erase previously drawn content
carefully, without using a built-in method to erase the entire frame (though it
is possible).

The code architecture is inspired by the Elm approach.

## About Nim

Ranges (with `..`) are... inclusive!??

Note that it's a little annoying when runtime error occurs, the terminal is not
able to be reset into its original mode (no `defer` in nim, I believe?). To
debug this, init illwill with `fullscreen=false` to see the error message.
