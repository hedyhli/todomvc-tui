package main

import (
	"fmt"
	"strings"

	"git.sr.ht/~rockorager/vaxis"
	vaxisBorder "git.sr.ht/~rockorager/vaxis/widgets/border"
	"git.sr.ht/~rockorager/vaxis/widgets/textinput"
)


var DefaultStyle = vaxis.Style{Foreground: vaxis.Color(0), Background: vaxis.Color(0)}
// Style of the border when the component is focused.
var FocusedStyle = vaxis.Style{Foreground: vaxis.RGBColor(200, 0, 0), Background: vaxis.Color(0)}
// Style of the placeholder for the input
var PlaceholderStyle = vaxis.Style{Foreground: vaxis.RGBColor(100, 100, 100)}
const Placeholder = "What needs to be done?"
const (
	uiSides = 25
	uiHeaderHeight = 10
	uiListHeight = 20
)


// Utils ///////////////////////////////////////////////
// seg is a shortcut function that returns a new Segment with a given text and
// style.
func seg(text string, style vaxis.Style) vaxis.Segment {
	return vaxis.Segment{Text: text, Style: style}
}

func drawCentered(text string, row int, win vaxis.Window) {
	win.Println(row, vaxis.Segment{
		Text: strings.Repeat(" ", win.Width / 2 - len(text) / 2) + text,
	})
}

// Draw a right-aligned text at a given row with style in the window.
func drawRight(text string, row int, win vaxis.Window) {
	win.Println(row, vaxis.Segment{
		Text: strings.Repeat(" ", win.Width - len(text)) + text,
	})
}

// Draw a left-aligned text at a given row with style in the window.
func drawLeft(text string, row int, win vaxis.Window, style vaxis.Style) {
	win.Println(row, seg(
		text + strings.Repeat(" ", win.Width - len(text)),
		style,
	))
}

// Data ////////////////////////////////////////////////
type Todo struct {
	name string
	complete bool
}

func (t *Todo) toggle() {
	t.complete = !t.complete
}

// fmt returns a formatted string for display on each item in the Todolist.
func (t *Todo) fmt() (s string) {
	s = "( ) "
	if t.complete {
		s = "(X) "
	}
	s += t.name
	return
}

// The state for the Todolist component.
type Todolist struct {
	l []Todo
	cur int
	// Top of viewport during scrolling
	top int
	// Number of items fully in view
	inView int
}

// Message types sent from list update method to the main handler to determine
// which parts of the list to redraw.
type ListRedrawType = int
const (
	ListRedrawNone ListRedrawType = iota
	ListRedrawAll
)

// fmtItemsleft returns a string for display in the itemsleft componenet.
func (tl *Todolist) fmtItemsleft() string {
	if len(tl.l) == 0 {
		return ""
	}

	n := 0
	for _, t := range tl.l {
		if !t.complete {
			n += 1
		}
	}
	switch n {
	case 0: return "woohoo! all done."
	case 1: return "1 item left"
	default: return fmt.Sprintf("%d items left", n)
	}
}

// Draw todo items in the given window
func (tl *Todolist) draw(win vaxis.Window) {
	win.Clear()
	row := 0

	i := tl.top
	last := tl.top + tl.inView
	if last > len(tl.l) {
		last = len(tl.l)
	}
	for i < last {
		style := vaxis.Style{Foreground: vaxis.Color(0), Background: vaxis.Color(0)}
		if i == tl.cur {
			style.Background = vaxis.RGBColor(60, 60, 65)
		}
		win.Println(row, seg(strings.Repeat(" ", win.Width), style))
		row += 1
		drawLeft("  " + tl.l[i].fmt(), row, win, style)
		row += 1
		win.Println(row, seg(strings.Repeat(" ", win.Width), style))
		row += 1

		i += 1
	}
}

// Updates scroll to ensure current selection is visible
func (tl *Todolist) ensureVisible() {
	if tl.cur < tl.top {
		tl.top = tl.cur
	} else if tl.cur >= tl.top + tl.inView {
		tl.top = tl.cur - tl.inView + 1
	}
}

func (tl *Todolist) selectOffset(offset int) (changed bool) {
	changed = false
	newCur := tl.cur + offset
	if newCur >= 0 && newCur < len(tl.l) {
		tl.cur = newCur
		tl.ensureVisible()
		changed = true
	}
	return
}

// update reacts to a given vaxis TUI event and updates the selection of the
// Todolist.
func (tl *Todolist) update(ev vaxis.Event) (redrawType ListRedrawType) {
	redrawType = ListRedrawNone
	if key, ok := ev.(vaxis.Key); ok {
		switch key.String() {
		case "Down", "j":
			if tl.selectOffset(1) {
				redrawType = ListRedrawAll
			}
		case "Up", "k":
			if tl.selectOffset(-1) {
				redrawType = ListRedrawAll
			}
		case "Ctrl+d":
			if tl.selectOffset(tl.inView / 2) {
				redrawType = ListRedrawAll
			}
		case "Ctrl+u":
			if tl.selectOffset(-tl.inView / 2) {
				redrawType = ListRedrawAll
			}
		case "Page_Down":
			if tl.selectOffset(tl.inView) {
				redrawType = ListRedrawAll
			}
		case "Page_Up":
			if tl.selectOffset(-tl.inView) {
				redrawType = ListRedrawAll
			}
		case "space", "Enter":
			tl.l[tl.cur].toggle()
			redrawType = ListRedrawAll
		}
	}
	return
}

// Add a new item to the todolist and updates selection and scroll to select
// the new item.
func (tl *Todolist) add(name string) {
	tl.l = append(tl.l, Todo{name: name, complete: false})
	tl.cur = len(tl.l) - 1
	tl.ensureVisible()
}

// App /////////////////////////////////////////////////
type Focus int
const (
	FocusInput Focus = iota
	FocusList
)

type Model struct {
	focus Focus
	list Todolist
	win struct {
		// Windows that require updating independently, they are initialized in
		// the drawRoot method.
		root vaxis.Window
		input vaxis.Window
		list vaxis.Window
		itemsleft vaxis.Window
	}
	wid struct {
		input *textinput.Model
	}
}

// UI //////////////////////////////////////////////////
func (model *Model) drawRoot(vx *vaxis.Vaxis) {
	root := vx.Window()
	root.Clear()
	model.win.root = root

	inputBorder := DefaultStyle
	listBorder := FocusedStyle
	if model.focus == FocusInput {
		inputBorder = FocusedStyle
		listBorder = DefaultStyle
	}

	// Centered column with uiSides on each side
	mainWin := root.New(uiSides, 0, root.Width - uiSides - uiSides, root.Height)
	row := 0

	// Header
	drawCentered("T O D O M V C", 5, mainWin)
	row += uiHeaderHeight

	// Input border
	inputOuterWin := mainWin.New(0, row, mainWin.Width, 3)
	model.win.input = mainWin.New(2, row + 1, mainWin.Width - 2 - 1, 1)
	vaxisBorder.All(inputOuterWin, inputBorder)
	// Input
	model.drawInput(vx)
	row += 3

	// Todolist border
	listOuterWin := mainWin.New(0, row, mainWin.Width, uiListHeight)
	model.win.list = mainWin.New(1, row + 1, mainWin.Width - 2, uiListHeight - 2)
	model.list.inView = (uiListHeight - 2) / 3
	vaxisBorder.All(listOuterWin, listBorder)
	// Todolist
	model.list.draw(model.win.list)
	row += uiListHeight

	// Itemsleft
	itemsleftWin := mainWin.New(0, row, mainWin.Width - 1, 1)
	model.win.itemsleft = itemsleftWin
	model.drawItemsleft()
}

func (model *Model) drawInput(vx *vaxis.Vaxis) {
	win := model.win.input
	widget := model.wid.input
	win.Clear()

	if model.focus == FocusInput {
		win.ShowCursor(widget.CursorPosition(), 0, vaxis.CursorBeamBlinking)
	} else {
		vx.HideCursor()
	}

	if len(widget.String()) == 0 {
		win.Println(0, seg(Placeholder, PlaceholderStyle))
	} else {
		widget.Draw(win)
	}
}

func (model *Model) drawItemsleft() {
	model.win.itemsleft.Clear()
	drawRight(model.list.fmtItemsleft(), 0, model.win.itemsleft)
}

func main() {
	vx, err := vaxis.New(vaxis.Options{})
	if err != nil {
		panic(err)
	}
	defer vx.Close()

	model := Model{
		focus: FocusInput,
		list: Todolist{l: []Todo{}, cur: 0},
	}

	inputWid := textinput.New()
	inputWid.HideCursor = true

	model.wid.input = inputWid
	model.drawRoot(vx)

	for ev := range vx.Events() {
		switch ev := ev.(type) {
		case vaxis.Key:
			switch ev.String() {
			case "Ctrl+c":
				return
			case "Ctrl+l":
				model.drawRoot(vx)
			case "Tab":
				switch model.focus {
				case FocusInput:
					model.focus = FocusList
				case FocusList:
					model.focus = FocusInput
				}
				// Technically only borders need to be redrawn, but borders are
				// not stored in the model context and just redrawing the whole
				// thing is fast enough for now.
				model.drawRoot(vx)
			default:
				if model.focus == FocusInput {
					inputWid.Update(ev)
					switch ev.String() {
					case "Enter":
						model.list.add(inputWid.String())
						inputWid.SetContent("")
						model.list.draw(model.win.list)
						model.drawItemsleft()
					}
					model.drawInput(vx)
				} else {
					switch model.list.update(ev) {
					case ListRedrawAll:
						model.list.draw(model.win.list)
						model.drawItemsleft()
					}
				}
			}
		case vaxis.Resize:
			model.drawRoot(vx)
		}

		vx.Render()
	}
}
