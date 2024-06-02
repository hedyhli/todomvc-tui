import std/sequtils
import std/strformat
import std/strutils

import illwill

const sides = 30

# todo ###########################################################
type Todo = ref object
  name: string
  complete: bool

proc newTodo(name: string): Todo =
  Todo(name: name, complete: false)

method toggle(self: Todo) =
  ## Toggle completion state
  self.complete = not self.complete

method format(self: Todo): string =
  ## Format this item for display in a todolist.
  return (if self.complete: "(X)" else: "( )") & " " & self.name

# todolist #######################################################
type Todolist = ref object
  s: seq[Todo]         ## The list
  cur: Natural         ## Index of currently highlighted item
  scroll_top: Natural  ## Index of first item in viewport

type ListAction = enum
  edit
  none

proc initTodolist(): Todolist =
  Todolist(s: @[], cur: 0, scroll_top: 0)

method incompleteCount(self: Todolist): Natural =
  ## Number of incomplete items in the todolist
  return self.s.filterIt(not it.complete).len()

method itemsleft(self: Todolist): string =
  let n = self.incompleteCount()
  case n:
    of 0: return "woohoo! all done"
    of 1: return "1 item left"
    else: return fmt"{n} items left"

method render(self: Todolist, t: var TerminalBuffer, focused: bool) =
  ## Render the list items and itemsleft to the terminal buffer
  # Frame
  const height = 19
  let width = t.width() - sides - sides
  # List has an internal vertical padding of 1 row, items have an empty line
  # between them
  const max_items = (height - 1) div 2  ## Max number of items in viewport
  t.setForegroundColor(if focused: fgRed else: fgWhite)
  t.drawRect(sides, 13, t.width() - sides, 14 + height)
  t.write(resetStyle)

  # Itemsleft right aligned
  if self.s.len > 0:
    let itemsleft = self.itemsleft()
    t.write(
      sides, 14 + height + 1,
      ' '.repeat(width - itemsleft.len),
      itemsleft
    )

  # Items
  if self.s.len == 0:
    return

  const top = 14 + 1

  var last_index = self.scroll_top + max_items - 1
  if last_index >= self.s.len:
    last_index = self.s.len - 1

  for i in self.scroll_top .. last_index:
    let item = self.s[i].format()
    if i == self.cur:
      t.write(styleReverse)

    t.write(
      sides + 2, top + (i - self.scroll_top) * 2,
      item, resetStyle,
      # Erase the remaining line
      ' '.repeat(width - 2 - item.len)
    )

method scroll_viewport(self: var Todolist) =
  ## Ensure current item is visible in viewport.
  # XXX: from self.render
  let items = 9

  # Bottom item in viewport
  if self.cur >= self.scroll_top + items:
    self.scroll_top = self.cur - items + 1
  # Top item in viewport
  elif self.cur < self.scroll_top:
    self.scroll_top = self.cur

method select_by(self: var Todolist, offset: int) =
  ## Change the current selection index by an offset and ensure it is visible
  ## in viewport.
  var new: int = self.cur + offset

  if new > self.s.len - 1:
    new = self.s.len - 1
  elif new < 0:
    new = 0

  self.cur = new
  self.scroll_viewport()

method add(self: var Todolist, todo: Todo) =
  self.s.add(todo)
  self.cur = self.s.len - 1
  self.scroll_viewport()

method handle_key(self: var Todolist, key: Key): ListAction =
  case key:
    of Key.Down, Key.J:
      self.select_by(1)
    of Key.Up, Key.K:
      self.select_by(-1)
    of Key.CtrlD:
      self.select_by(4)
    of Key.CtrlU:
      self.select_by(-4)
    of Key.PageDown:
      self.select_by(8)
    of Key.PageUp:
      self.select_by(-8)
    of Key.Enter, Key.Space:
      self.s[self.cur].toggle()
    of Key.E:
      return ListAction.edit
    else: discard
  return ListAction.none

# input ##########################################################
type Input = ref object
  s: string
  cursor: int

type InputAction = enum
  ## Useful action to be done by app after the input widget handles a key
  ## event.
  enter
  escape
  none

method render(self: Input, t: var TerminalBuffer, focused: bool) =
  ## Render the input and cursor to the terminal buffer
  let width = t.width() - sides - sides
  const before = 10   ## Number of rows before this widget
  const top = 1       ## Top padding
  const left = 2      ## Left padding
  const placeholder = "What needs to be done?"
  let placeholderStyle = fgBlue

  if focused:
    t.setForegroundColor(fgRed)
  else:
    t.setForegroundColor(fgWhite)

  t.drawRect(sides, 10, t.width() - sides, 10 + 2)
  t.resetAttributes()

  if not focused:
    if self.s.len == 0:
      # Just placeholder
      t.write(
        sides + left, before + top,
        placeholderStyle, placeholder,
        resetStyle, ' '.repeat(width - left - placeholder.len - 1)
      )
    else:
      # Just input
      t.write(sides + left, before + top, self.s, ' '.repeat(width - left - self.s.len - 1))
    return

  if self.s.len == 0:
    # Cursor + placeholder
    t.write(
      sides + left, before + top,
      styleReverse, placeholder[0] & "", resetStyle,
      placeholderStyle, placeholder[1..^1],
      resetStyle, ' '.repeat(width - left - placeholder.len - 1)
    )
    return

  # Cursor + input
  if self.cursor < self.s.len:
    t.write(
      sides + left, before + top,
      # Input before cursor
      self.s[0..self.cursor - 1],
      # Cursor
      styleReverse, self.s[self.cursor] & "",
      # Rest of input
      resetStyle,   self.s[self.cursor + 1 .. self.s.len-1],
      # Rest of the line
      ' '.repeat(width - left - self.s.len - 1)
    )
  else:
    t.write(
      sides + left, before + top,
      self.s,
      # Cursor
      styleReverse, " ",
      # Rest of line
      resetStyle, ' '.repeat(width - left - self.s.len - 1)
    )

method clear(self: var Input) =
  self.s = ""
  self.cursor = 0

method clamp(self: var Input) =
  if self.cursor < 0:
    self.cursor = 0
  elif self.cursor > self.s.len:
    self.cursor = self.s.len

method left(self: var Input) =
  self.cursor -= 1
  self.clamp()

method right(self: var Input) =
  self.cursor += 1
  self.clamp()

method insert(self: var Input, ch: string) =
  self.s = self.s[0..self.cursor-1] & ch & self.s[self.cursor..self.s.len-1]
  self.cursor += 1

method delete_left(self: var Input) =
  ## Backspace key
  if self.cursor > 0:
    self.s = self.s[0..self.cursor-2] & self.s[self.cursor..self.s.len-1]
    self.cursor -= 1

method delete_right(self: var Input) =
  ## Delete key
  if self.cursor < self.s.len:
    self.s = self.s[0..self.cursor-1] & self.s[self.cursor+1..self.s.len-1]

method handle_key(self: var Input, key: Key): InputAction =
  case key:
    of Key.Left:
      self.left()
    of Key.Right:
      self.right()
    of Key.Backspace:
      self.delete_left()
    of Key.Delete:
      self.delete_right()
    of Key.CtrlA, Key.Home:
      self.cursor = 0
    of Key.CtrlE, Key.End:
      self.cursor = self.s.len
    of Key.Escape:
      return InputAction.escape
    of Key.Enter:
      return InputAction.enter
    else:
      var code = ord(key.char)
      # Rather fragile method to check if key is printable
      if (code >= 32 and code <= 64 + 26) or (code >= 91 and code <= 126):
        self.insert($key.char)
  return InputAction.none

# model ##########################################################
type Focus = enum
  input, list

type Model = ref object
  t: TerminalBuffer
  focus: Focus
  list: Todolist
  input: Input

# init ##########################################################
proc init() =
  ## Set up the TUI and initialize a model state

  illwillInit(fullscreen=true)

  proc exitProc() {.noconv.} =
    illwillDeinit()
    showCursor()
    quit(0)

  setControlCHook(exitProc)
  hideCursor()

# view ###########################################################
proc view(m: Model) =
  ## Render entire TUI based on the current state
  # Center-aligned header
  const title = "T O D O M V C"
  m.t.write(int(m.t.width() / 2 - title.len / 2), 7, title)

  # Widgets
  m.input.render(m.t, m.focus == Focus.input)
  m.list.render(m.t, m.focus == Focus.list)

  m.t.display()

# update #########################################################
proc update(m: Model, key: Key) =
  ## Update the modal state given user key input
  if key == Key.Tab:
    case m.focus:
      of Focus.input: m.focus = Focus.list
      of Focus.list: m.focus = Focus.input
    return
  case m.focus:
    of Focus.input:
      case m.input.handle_key(key):
        of InputAction.enter:
          m.list.add(newTodo(m.input.s))
          m.input.clear()
        else: discard
    of Focus.list:
      discard m.list.handle_key(key)

# main ###########################################################
var model = Model(
  t: newTerminalBuffer(terminalWidth(), terminalHeight()),
  focus: Focus.input,
  list: initTodolist(),
  input: Input(s: "", cursor: 0),
)

init()

# Quite the 'MVC' as part of TodoMVC-TUI!
while true:
  view(model)
  var key = getKey()
  case key:
    # Don't redraw until there is a user event
    of Key.None: continue
    else: update(model, key)
