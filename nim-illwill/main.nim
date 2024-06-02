import std/sequtils
import std/strutils

import illwill

const sides = 30

# todos ##########################################################
type Todo = ref object
  name: string
  complete: bool

proc newTodo(name: string): Todo =
  Todo(name: name, complete: false)

method toggle(self: Todo) =
  self.complete = not self.complete

method format(self: Todo): string =
  return (if self.complete: "(X)" else: "( )") & " " & self.name

type Todolist = ref object
  s: seq[Todo]
  cur: Natural

type ListAction = enum
  edit
  none

proc initTodolist(): Todolist =
  Todolist(s: @[], cur: 0)

method incompleteCount(self: Todolist): int =
  self.s.filterIt(not it.complete).len()

method render(self: Todolist, t: var TerminalBuffer, focused: bool) =
  if focused:
    t.setForegroundColor(fgRed)
  else:
    t.setForegroundColor(fgWhite)
  t.drawRect(sides, 13, t.width() - sides, 14 + 20)
  let top = 14
  for i, item in self.s:
    if i == self.cur:
      t.write(styleReverse)
    t.write(sides + 2, top + i*2, item.format())
    t.write(resetStyle)

method scroll_viewport(self: Todolist) =
  ## Ensure current item is visible in viewport

method select_by(self: Todolist, offset: int) =
  var new: int = self.cur + offset
  if new > self.s.len - 1:
    new = self.s.len - 1
  elif new < 0:
    new = 0
  self.scroll_viewport()

method add(self: Todolist, todo: Todo) =
  self.s.add(todo)
  self.cur = self.s.len - 1

method handle_key(self: Todolist, key: Key): ListAction =
  case key:
    of Key.Down:
      self.select_by(1)
    of Key.Up:
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
  let width = t.width() - sides - sides

  if focused:
    t.setForegroundColor(fgRed)
  else:
    t.setForegroundColor(fgWhite)

  t.drawRect(sides, 10, t.width() - sides, 10 + 2)
  t.resetAttributes()

  if self.cursor < self.s.len:
    t.write(
      sides + 2, 10 + 1,
      self.s[0..self.cursor - 1],
      styleReverse, self.s[self.cursor] & "",
      resetStyle,   self.s[self.cursor + 1 .. self.s.len-1]
    )
    # Rest of the line
    t.write(sides + 2 + self.s.len, 10 + 1, resetStyle, ' '.repeat(width - 2 - self.s.len - 1))
  else:
    t.write(sides + 2, 10 + 1, self.s, styleReverse, " ", resetStyle, ' '.repeat(width - 2 - self.s.len - 1))

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
  self.s = self.s[0..self.cursor-2] & self.s[self.cursor..self.s.len-1]
  self.cursor -= 1

method delete_right(self: var Input) =
  ## Delete key
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
      var char = $key.char
      self.insert(char)
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

  # Input
  m.input.render(m.t, m.focus == Focus.input)

  # List
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
    of Focus.list: discard m.list.handle_key(key)

# main ###########################################################
var model = Model(
  t: newTerminalBuffer(terminalWidth(), terminalHeight()),
  focus: Focus.input,
  list: initTodolist(),
  input: Input(s: "", cursor: 0),
)

init()

while true:
  view(model)
  var key = getKey()
  case key:
    # Don't redraw until there is a user event
    of Key.None: continue
    else: update(model, key)
