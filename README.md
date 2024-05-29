
## Status

- Go
  - [x] tview
  - gocui
    Supports adding and toggling
  - (planned) bubbletea

- Rust
  - ratatui
    fully featured except mouse support and a "proper" modal UI for editing

- Lua
  - (planned) ltui
  - (planned) notcurses?

- (planned) Nim
- (planned) C

- Python
  - [x] Textual
  - (planned) Curses

- (planned) Some lisps

## Spec

(loosely formatted)

See implementations marked with `[x]` as flagship/example implementations.

### code

Everything should be in a single file unless *absolutely necessary*.

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
