import illwill

# model ##########################################################
type Focus = enum
  input, list

type Model = object
  ## Basic application state
  t: TerminalBuffer
  focus: Focus

proc init(): Model =
  ## Set up the TUI and initialize a model state

  illwillInit(fullscreen=true)
  proc exitProc() {.noconv.} =
    illwillDeinit()
    showCursor()
    quit(0)
  setControlCHook(exitProc)
  hideCursor()

  var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

  result = Model(t: tb, focus: Focus.input)

  # 3. Display some simple static UI that doesn't change from frame to frame.
  tb.setForegroundColor(fgWhite, true)
  tb.drawRect(0, 0, 40, 5)
  tb.drawHorizLine(2, 38, 3, doubleStyle=true)

  tb.write(2, 1, fgWhite, "Press any key to display its name")
  tb.write(2, 2, "Press ", fgYellow, "ESC", fgWhite,
                 " or ", fgYellow, "Q", fgWhite, " to quit")
  return

# view ###########################################################
proc view(m: Model) =
  ## Render entire TUI based on the current state
  m.t.display()

# update #########################################################
proc update(m: Model, key: Key) =
  ## Update the modal state given user key input
  discard

# main ###########################################################
var modal = init()

while true:
  var key = getKey()
  case key:
    # Don't redraw until there is a user event
    of Key.None: continue
    else: update(modal, key)
  view(modal)
