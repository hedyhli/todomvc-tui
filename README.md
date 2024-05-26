
## Status

- Go
  - [x] tview
  - gocui
  - (planned) bubbletea
- Rust
  - ratatui
- Lua
  - ltui
  - notcurses?
- Nim
- C
- Python
  - [x] Textual
  - Curses
- Some lisps

## Spec

(loosely formatted)

### functionality

- Show N incomplete
- Button to confirm edit with modals
- Scrollable list view
- Input validation - must be non-empty string (whitespace trimmed)
- Button to clear all completed
- Button to mark all completed

### UI

- Hero with large padding top/bottom
- Center main section except key hints
- main section max-width 100
- New todo: height (excl borders) 3

### UX

- Keys to navigate
- Keys to toggle copmlete
- `e` to edit
- optionally key to delete
- Mouse to switch focus
