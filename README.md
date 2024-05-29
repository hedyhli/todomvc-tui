# TodoMVC on the TUI

![demo](./demo.png)

## Status

- Go
  - [x] tview

  - gocui

    Supports adding and toggling

  - (planned) bubbletea

- Rust

  - [x] ratatui

    fully featured except mouse support and a "proper" modal UI for editing

  - (planned) cursive, possibly

- Zig, but as it stands right now the ecosystem is limited.

- Lua (but written with Fennel, probably)
  - (planned) ltui
  - (planned) a C lib with bindings

- Nim
  - (planned) illwill

- C
  - (planned) ncurses, possibly

- Python
  - [x] Textual

    Does not have buttons for "mark all as completed" etc because I can't figure
    out how to have single-row buttons in textual, and using keybindings to do
    these operations instead is boring and trivial.

  - (probably not) urwid, curses

- (planned) Some lisps

- JS/TS
  - (planned) react-ink, probably.
  - (planned) solid-ink

- (planned) shell - bash or maybe even nushell.

- (planned) haskell

## Spec

(loosely formatted)

See implementations marked with `[x]` as flagship/example implementations.

### code

Everything should be in a single file unless *absolutely necessary*.

Tests may be added, and may or may not be in the same file.

### functionality

- Show N incomplete as text
- Button to confirm edit with modals
- Input validation - must be non-empty string (whitespace trimmed)
- Button to clear all completed
- Button to mark all completed

### UI

- Solid borders for input and todolist.
- Hero with large padding top/bottom
- Center main section except key hints
- main section max-width 100
- New todo: height (excl borders) 3
- N items left, right aligned under the todolist

### UX

- Keys to navigate
- Keys to toggle complete
- `e` to edit
- optionally key to delete
- Mouse to switch focus
- Input field should support basic emacs keys, optionally mouse support
- Scrollable list view
