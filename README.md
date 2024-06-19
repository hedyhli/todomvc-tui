# TodoMVC in the terminal

![demo](./demo.png)

**Table of Contents**

<!-- mtoc-start -->

* [Implementations](#implementations)
* [Roadmap](#roadmap)
* [Spec](#spec)
  * [Code](#code)
  * [Checks](#checks)
  * [Packaging](#packaging)
  * [functionality](#functionality)
  * [UI](#ui)
  * [UX](#ux)
  * [Internals](#internals)
* [Stats](#stats)
  * [Code](#code-1)
  * [Binary](#binary)
* [Contribute](#contribute)

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
  - (WIP) blessed
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

  - (WIP) lwd + nottui

- V
  - [x] `term.ui` (1.1, i1.1, u1.1)

    fully-featured with modal dialog (with darkened background) for editing, no mouse support.

- (planned) C++

- (WIP) Odin (using only `core:encoding/ansi`), also note some of these
  resources might be useful as an ad-hoc solution:
  https://github.com/odin-lang/Odin/discussions?discussions_q=terminal

- (planned) Odin -- Waiting for the core `terminal` package to be implemented: https://github.com/odin-lang/Odin/discussions/978

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

### Code

- All code should be in a single file unless required otherwise by the
  toolchain, in which case, stick to as little code splitting as possible for ease
  of comparison. The single file should be named `main.<ext>` unless required
  otherwise by the toolchain.
- Documentation on functions may be added
- A binary, if produced, or a project name if required, should be named
  "todomvc-tui". Use "todomvc_tui" if dashes are not allowed.
- Directories are named `<language>-<framework>` where language is the full
  language name, followed by the framework/library used that does the primary
  heavy-lifting for the terminal.

### Checks

- Tests may be added, but they should not be in the `main.<ext>` file. For
  instance, the `rust-ratatui` implementation saves the actual code of the TUI in
  `src/main.rs`, and tests in `src/test.rs`, which is not needed for compiling the
  binary.
- Linting is not necessary, but recommended. (E.g. `cargo clippy`, `go vet`)
- An official style guide or formatting tool should be used if available. (E.g.
  `zig fmt`, `go fmt`)

### Packaging

A package definition file is not strictly necessary unless the toolchain
requires these files to compile.

- Some toolchains require package definition files to include a "version"
  number. The spec compatibility version number as used [here](#implementations)
  may be used. If SemVer is required, kindly keep the **patch** portion 0. For
  instance, `1.2` -> `1.2.0`. If the the version key is used, use only the
  version number for functionality, and omit ones for UI, internals, or other
  prefixed versions.
- The author of the implementation should be the one listed in the author field,
  if required.
- The repository field should be set to https://github.com/hedyhli/todomvc-tui.
- If the documentation field is required, set it to the same as repository
  field.
- The implementation "project" should only specify an executable. A provided
  library should NOT be defined.
- The package itself should NOT be published.

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

Kindly take these at face value and analyze at will in conjunction with the spec
feature versions as listed [at the top](#implementations).

The command snippets, which are in [Nu](https://www.nushell.sh/), are provided
as a rough overview of the commands run in the [stats script](.scripts/stat.nu)
with the formatting code removed to get the idea across.

Last updated 2024-06-10

### Code

```nushell
( scc --by-file -f csv --sort code --uloc
  rust-ratatui/src/main.rs go-tview/main.go # ...
  | from csv | select Filename Code Comments Complexity ULOC | to md )
```

Kindly read in conjunction with the [implementation](#implementations) spec
compatibility version numbers, and keep in mind *this is not a code-golfing
competition*!

<!--begin-stats-code-->
|File|Code|ULOC|Comments|Complexity|
|-|-|-|-|-|
|**rust-ratatui** (src/main.rs)|407|345|31|63|
|**v-term-ui** (main.v)|348|287|38|86|
|**go-vaxis** (main.go)|338|290|36|44|
|**zig-libvaxis** (src/main.zig)|326|308|48|78|
|**nim-illwill** (main.nim)|247|270|47|25|
|**go-tview** (main.go)|181|162|3|21|
|**python-textual** (main.py)|180|146|5|9|
<!--end-->

### Binary

Each implementation here is compiled using a command as listed below, then the
binary is moved to `../bin/<name-of-dir-as-exe-name>`.

<details><summary>Toolchain specs</summary>

Rust
```
stable-aarch64-apple-darwin (default)
rustc 1.77.2 (25ef9e3d8 2024-04-09)
```
- `cargo build --release`

Go
```
go version go1.19.5 darwin/arm64
```
- `go build`

Zig
- version 0.13.0
- `zig build --release=<annotated>`

<!--
zig build --release=small && cp zig-out/bin/todomvc-tui ../bin/zig-libvaxis-small
zig build --release=safe && cp zig-out/bin/todomvc-tui ../bin/zig-libvaxis-safe
zig build --release=fast && cp zig-out/bin/todomvc-tui ../bin/zig-libvaxis-fast

DO Repeat Yourself.
-->

Nim
```
Nim Compiler Version 2.0.0 [MacOSX: arm64]
Compiled at 2023-08-01
```
- `nim c main.nim`

V
```
V 0.4.6 6b2d527
```
- `v main.v`

</details>

```nushell
ls bin | sort-by -r size | select name size | to md
```

<!--begin-stats-size-->
|Name|Size|
|-|-|
|go-tview|3.8 MiB|
|go-vaxis|2.9 MiB|
|rust-ratatui|711.3 KiB|
|v-term-ui|630.6 KiB|
|zig-libvaxis (safe)|389.4 KiB|
|zig-libvaxis (fast)|324.5 KiB|
|nim-illwill|289.8 KiB|
|zig-libvaxis (small)|153.9 KiB|
<!--end-->

It might be interesting to use PyInstaller for `python-*` implementations here
to compare binary sizes with AOT-compiled languages, but I am not yet interested
in installing PyInstaller just for this single purpose. This can be done once I
set up CI that will automate generating these tables.

## Contribute

[Send PRs](https://github.com/hedyhli/todomvc/pulls) | [Send
Patches](mailto:~hedy/inbox@lists.sr.ht)

The spec isn't yet finalized, but I'm happy to review PRs/patches that introduce
new implementations with the same features and UI as any of the existing ones,
either in another language, or another framework of an existing language. Such
as... more lisps!
