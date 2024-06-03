package main

import (
	"fmt"
	"strings"

	"git.sr.ht/~rockorager/vaxis"
	vaxisBorder "git.sr.ht/~rockorager/vaxis/widgets/border"
	"git.sr.ht/~rockorager/vaxis/widgets/textinput"
)

// Utils ///////////////////////////////////////////////
func seg(text string, style vaxis.Style) vaxis.Segment {
	return vaxis.Segment{Text: text, Style: style}
}

// Data ////////////////////////////////////////////////
type Todo struct {
	name string
	complete bool
}

func (t *Todo) toggle() {
	t.complete = !t.complete
}

func (t *Todo) fmt() (s string) {
	s = "( ) "
	if t.complete {
		s = "(X) "
	}
	s += t.name
	return
}

type Todolist struct {
	l []Todo
	cur int
	// Top of viewport during scrolling
	top int
}

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
	case 0: return "woohoo! nothing left!"
	case 1: return "1 item left"
	default: return fmt.Sprintf("%d items left", n)
	}
}

func (tl *Todolist) draw(win vaxis.Window) {
	row := 0
	for i, t := range tl.l {
		style := vaxis.Style{Foreground: vaxis.Color(0), Background: vaxis.Color(0)}
		if i == tl.cur {
			style.Background = vaxis.RGBColor(60, 60, 65)
		}
		win.Println(row, seg(strings.Repeat(" ", win.Width), style))
		row += 1
		drawLeft("  " + t.fmt(), row, win, style)
		row += 1
		win.Println(row, seg(strings.Repeat(" ", win.Width), style))
		row += 1
	}
}

func (tl *Todolist) update(ev vaxis.Event) {
	if key, ok := ev.(vaxis.Key); ok {
		switch key.String() {
		case "Down", "j":
			if tl.cur < len(tl.l) - 1 {
				tl.cur += 1
			}
		case "Up", "k":
			if tl.cur > 0 {
				tl.cur -= 1
			}
		case "space", "Enter":
			tl.l[tl.cur].toggle()
		}
	}
}

func (tl *Todolist) add(name string) {
	tl.l = append(tl.l, Todo{name: name, complete: false})
	tl.cur = len(tl.l) - 1
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
}

// UI //////////////////////////////////////////////////
var DefaultStyle = vaxis.Style{Foreground: vaxis.Color(0), Background: vaxis.Color(0)}
var FocusedStyle = vaxis.Style{Foreground: vaxis.RGBColor(200, 0, 0), Background: vaxis.Color(0)}
var PlaceholderStyle = vaxis.Style{Foreground: vaxis.RGBColor(100, 100, 100)}
const Placeholder = "What needs to be done?"
const (
	uiSides = 25
)

func drawCentered(text string, row int, win vaxis.Window) {
	win.Println(row, vaxis.Segment{
		Text: strings.Repeat(" ", win.Width / 2 - len(text) / 2) + text,
	})
}

func drawRight(text string, row int, win vaxis.Window) {
	win.Println(row, vaxis.Segment{
		Text: strings.Repeat(" ", win.Width - len(text)) + text,
	})
}

func drawLeft(text string, row int, win vaxis.Window, style vaxis.Style) {
	win.Println(row, seg(
		text + strings.Repeat(" ", win.Width - len(text)),
		style,
	))
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

	for ev := range vx.Events() {
		switch ev := ev.(type) {
		case vaxis.Key:
			switch ev.String() {
			case "Ctrl+c":
				return
			case "Tab":
				switch model.focus {
				case FocusInput:
					model.focus = FocusList
				case FocusList:
					model.focus = FocusInput
				}
			}
		}

		if model.focus == FocusInput {
			inputWid.Update(ev)
			if key, ok := ev.(vaxis.Key); ok {
				switch key.String() {
				case "Enter":
					model.list.add(inputWid.String())
					inputWid.SetContent("")
				}
			}
		} else {
			model.list.update(ev)
		}

		// Render
		root := vx.Window()
		root.Clear()

		// Centered column with uiSides on each side
		main := root.New(uiSides, 0, root.Width - uiSides - uiSides, root.Height)

		// Header
		drawCentered("T O D O M V C", 5, main)

		// Input
		inputOuterWin := main.New(0, 10, main.Width, 3)
		inputWin := main.New(2, 11, main.Width - 2 - 1, 1)
		if model.focus == FocusInput {
			vaxisBorder.All(inputOuterWin, FocusedStyle)
			inputWin.ShowCursor(inputWid.CursorPosition(), 0, vaxis.CursorBeamBlinking)
		} else {
			vaxisBorder.All(inputOuterWin, DefaultStyle)
			vx.HideCursor()
		}


		if len(inputWid.String()) == 0 {
			// Placeholder
			inputWin.Println(0, seg(Placeholder, PlaceholderStyle))
		} else {
			inputWid.Draw(inputWin)
		}

		// Todolist
		listHeight := 20
		listOuterWin := main.New(0, 10 + 3, main.Width, listHeight)
		if model.focus == FocusList {
			vaxisBorder.All(listOuterWin, FocusedStyle)
		} else {
			vaxisBorder.All(listOuterWin, DefaultStyle)
		}
		listWin := main.New(1, 10 + 3 + 1, main.Width - 2, listHeight - 2)
		model.list.draw(listWin)

		itemsleftWin := main.New(0, 10 + 3 + listHeight, main.Width - 1, 1)
		drawRight(model.list.fmtItemsleft(), 0, itemsleftWin)

		vx.Render()
	}
}
