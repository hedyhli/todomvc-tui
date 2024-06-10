# TodoMVC in the terminal

![demo](./demo.png)


<!-- mtoc-start -->

* [Implementations](#implementations)
* [Roadmap](#roadmap)
* [Spec](#spec)
  * [code](#code)
  * [functionality](#functionality)
  * [UI](#ui)
  * [UX](#ux)
  * [Internals](#internals)
* [Stats](#stats)
  * [Code](#code-1)
  * [Binary](#binary)

<!-- mtoc-end -->

## Implementations

- Go
  - [x] tview (2.0 without validation, i1.0, u1.5)

    Note that the edit modal does not apply a darkened background.

  - gocui (possibly 1.0, UI was made before the specification solidified)

    Supports adding and toggling

  - (planned) bubbletea

  - [x] vaxis (1.1 without buttons, i1.1, u1.1) edit modal does not apply a
    darkened background

- Rust

  - [x] ratatui (1.2, i1.1, u1.0)

    fully featured except mouse support and a "proper" modal UI for editing.
    Note, editing is supported by borrowing the newtodo input widget.

  - (maybe?) cursive, requires ncurses

  - (STALLED) zi (-, -, u1.5)

    interestingly, there's a "todos" example in the Zi repository where the code
    explicitly declares a "TodoMvc" component. However, it does not fully
    implement what this specification requires, nor looks like the actual
    TodoMVC, it does however provide many extra features than these
    implementations.

  - (planned) tui-realm

- Zig
  - libvaxis (1.0, i1.1, i1.0)

- Lua (but written with Fennel, probably)
  - (planned) ltui
  - (planned) a C lib with bindings

- Nim

  - [x] illwill (1.0, i1.1, u1.0)
    
    Similar in terms of functionality (& limitations) as the V-lang
    implementation. One difference being that modal dialog for editing is not
    implemented.

  - (planned) nimwave

- C
  - (planned) ncurses, possibly

- Python
  - [x] Textual (2.0 without buttons, i1.0, u1.5)

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

- OCaml

  - (STALLED) minttea
    
    waiting for 0.0.3 to be released (https://github.com/leostera/minttea/issues/54)

  - (STALLED) lwd + nottui

- V
  - [x] `term.ui` (1.1, i1.1, u1.1)

    fully-featured with modal dialog (with darkened background) for editing, no mouse support.

- (planned) C++

## Roadmap

- [x] finish V version
- [x] frame for nim illwill
- [x] continue with nim
- [x] attempt at frame for go vaxis
- [ ] finalize UI and formalize it into spec
- [x] attempt at rust Zi
- [ ] update older impl to new UI spec
- [x] finish go vaxis
- [ ] finish rust Zi
- [x] attempt at Zig libvaxis
- [ ] finish Zig libvaxis

## Spec

(loosely formatted)

Implementations marked with `[x]` are deemed "complete". They should satisfy
at least version 1.0 as described below.

The "version" numbering next to bullet points gives a sense of the priority of a
given feature for implementations. Ideally, an implementation that targets a
version number of X should implement ALL features tagged with version X and
lower.

### code

- All code should be in a single file unless required otherwise by the
  toolchain, in which case, stick to as little code splitting as possible for ease
  of comparison. The single file should be named `main.<ext>` unless required
  otherwise by the toolchain.
- Tests may be added, and may or may not be in the same file
- Documentation on functions may be added
- A binary, if produced, or a project name if required, should be named
  "todomvc-tui". Use "todomvc_tui" if dashes are not allowed.
- Directories are named `<language>-<framework>` where language is the full
  language name, followed by the framework/library used that does the primary
  heavy-lifting for the terminal.

### functionality

- 0.1: Show N incomplete as text
- 1.0: Button to confirm edit with modals
- 1.2: Button to clear all completed
- 1.2: Button to mark all completed
- 2.0: Input validation - must be non-empty string (whitespace trimmed)

### UI

These **must** be followed, by convention and for consistency.

Version numbers prefixed with `u` are tracked separately.

- u0.1: Hero with large padding top/bottom
- u0.1: New todo: height (including borders) 3
- u1.0: Solid borders for input and todolist.
- u1.0: Different style/color of borders determines focus
- u1.0: Centered main section
- u1.0: itemsleft right aligned under the todolist
- u1.1: Edit modal applies a background overlay on top of other contents outside
  modal.
- u1.5: main section dynamically sized with ...

### UX

- 0.1: Keys to navigate
- 0.1: Input field should support basic emacs keys
- 0.1: Keys to toggle complete
- 1.0: Scrollable list view
- 1.1: `e` to edit
- 2.0: key to delete
- 2.0: Mouse to switch focus
- 2.0: Input field mouse support

### Internals

These version numbers prefixed with `i` are tracked separately.

- i1.0: structs for Todo
- i1.1: structs and methods for both Todo and Todolist
- i1.5: refactor input, list, and itemsleft as separate widgets with their own
  lifecycle/update methods
- i2.1: incremental re-renders (rather than re-drawing the entire screen on each
  update), or an alternative performance optimization of renders

## Stats

### Code

Notes:
- `scc --sort code <file1> <file2> <file3> ...`
- Only the `main.<ext>` file is used in analysis
- Last updated 2024-06-10

```
───────────────────────────────────────────────────────────────────────────────
Language                 Files     Lines   Blanks  Comments     Code Complexity
───────────────────────────────────────────────────────────────────────────────
Rust (ratatui)               1       523       49        42      432         81
Go (vaxis)                   1       423       49        36      338         44
V                            1       427       52        38      337         85
Zig (libvaxis)               1       410       59        41      310         77
Nim (illwill)                1       348       54        47      247         25
Go (tview)                   1       212       28         3      181         21
Python (textual)             1       210       25         5      180          9
───────────────────────────────────────────────────────────────────────────────
```

### Binary

Commands used:
- Rust
  - `cargo build --release`
- Go
  - `go build`
- Zig
  - `zig build --release=<annotated>`

Producing the table (Nushell): `ls | sort-by size | select size name`

Platform: macos aarch6

```
╭───┬───────────┬────────────────────╮
│ # │   size    │        name        │
├───┼───────────┼────────────────────┤
│ 0 │ 153.6 KiB │ zig-libvaxis-small │
│ 1 │ 289.8 KiB │ nim-illwill        │
│ 2 │ 324.3 KiB │ zig-libvaxis-fast  │
│ 3 │ 389.2 KiB │ zig-libvaxis-safe  │
│ 4 │ 630.5 KiB │ v-term-ui          │
│ 5 │ 711.4 KiB │ rust-ratatui       │
│ 6 │   2.9 MiB │ go-vaxis           │
│ 7 │   3.8 MiB │ go-tview           │
╰───┴───────────┴────────────────────╯
```
