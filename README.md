# TodoMVC in the terminal

![demo](./demo.png)

## Implementations

- Go
  - [x] tview

  - gocui

    Supports adding and toggling

  - (planned) bubbletea

  - (planned) vaxis

- Rust

  - [x] ratatui

    fully featured except mouse support and a "proper" modal UI for editing

  - (maybe?) cursive, requires ncurses
  - zi -- interestingly, there's a "todos" example in the Zi repository where
    the code explicitly declares a "TodoMvc" component. However, it does not fully
    implement what this specification requires, nor looks like the actual TodoMVC,
    it does however provide many extra features than these implementations.

- Zig
  - (planned) libvaxis

- Lua (but written with Fennel, probably)
  - (planned) ltui
  - (planned) a C lib with bindings

- Nim
  - [x] illwill
    
    Similar in terms of functionality (& limitations) as the V-lang implementation.

- C
  - (planned) ncurses, possibly

- Python
  - [x] Textual

    Does not have buttons for "mark all as completed" etc because I can't figure
    out how to have single-row buttons in textual, and using keybindings to do
    these operations instead is boring and trivial.

  - (probably NOT) urwid, curses
  - (planned) blessed
  - (planned) pytermgui

- (planned) Some lisps, hopefully.

- JS/TS
  - (planned) react-ink, probably.
  - (planned) solid-ink
  - (no) deno-tui does not seem customizable enough just yet to suit my needs
    (event handling)

- (planned) shell - bash or maybe even nushell.

- ~~haskell~~ - as much as I'd love to add it to the list, the tooling is
  extremely involved to setup (on my machine) right now.

- another ML?

- V
  - [x] `term.ui`

    fully-featured with modal dialog for editing, no mouse support.

## Roadmap

- [x] finish V version
- [x] frame for nim illwill
- [x] continue with nim
- [x] attempt at frame for go vaxis
- [ ] finalize UI and formalize it into spec
- [x] attempt at rust Zi
- [ ] update older impl to new UI spec
- [ ] finish go vaxis
- [ ] finish rust Zi
- [ ] attempt at Zig libvaxis
- [ ] finish Zig libvaxis

## Spec

(loosely formatted)

Implementations marked with `[x]` are deemed "complete". They should satisfy
_most_ of the requirements as listed below, in two or three areas more so,
possibly because the framework/library used provides certain functionality out
of the box.

### code

- All code should be in a single file unless required otherwise by the
  toolchain, in which case, stick to as little code splitting as possible for ease
  of comparison. The single file should be named `main.<ext>` unless required
  otherwise by the toolchain.
- Tests may be added, and may or may not be in the same file
- Documentation on functions may be added
- A binary, if produced, or a project name if required, should be named
  "todomvc-tui"
- directories are named `<language>-<framework>` where language is the full
  language name, followed by the framework/library used that does the primary
  heavy-lifting for the terminal.

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
