package main

import (
	"git.sr.ht/~rockorager/vaxis"
	"git.sr.ht/~rockorager/vaxis/widgets/textinput"
)

type Focus int

const (
	FocusInput Focus = iota
	FocusList
)

type model struct {
	focus Focus
}

var PlaceholderStyle = vaxis.Style{ Foreground: vaxis.RGBColor(100, 100, 100) }
const Placeholder = "What needs to be done?"

func main() {
	vx, err := vaxis.New(vaxis.Options{})
	if err != nil {
		panic(err)
	}
	defer vx.Close()

	ti := textinput.New()
	ti.HideCursor = true
	for ev := range vx.Events() {
		switch ev := ev.(type) {
		case vaxis.Key:
			switch ev.String() {
			case "Ctrl+c":
				return
			}
		}
		ti.Update(ev)
		vx.Window().Clear()
		vx.Window().ShowCursor(ti.CursorPosition(), 0, vaxis.CursorBeamBlinking)
		if len(ti.String()) == 0 {
			vx.Window().Println(0, vaxis.Segment{Text: Placeholder, Style: PlaceholderStyle})
		} else {
			ti.Draw(vx.Window())
		}
		vx.Render()
	}
}
