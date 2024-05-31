package main

import (
	"fmt"
	"log"
	"strings"

	"github.com/jroimartin/gocui"
	"github.com/gookit/color"
)

const ModShift = gocui.Modifier(1)
const ModCtrl = gocui.Modifier(4)

var cPlaceholder = color.HEX("#bbbbbb").C256()
var cSelectedBg = color.HEX("#555555", true).C256()

var g *gocui.Gui

var marginLeft = 20

type box struct {
	top int
	height int
}

var boxNewtodo = box{
	top: 5,
	height: 3,
}

var boxTodolist = box{
	top: 10,
	height: 20,
}

var boxItemsleft = box{
	top: 31,
	height: 2,
}

var emptyNewtodo = true

type item struct {
	name string
	complete bool
}

var views = []string{"newtodo", "todolist"}
var todolistIndex = 0
var items = []item{}

func must[T any](v T, err error) T {
	if err != nil {
		log.Fatalln(err.Error())
	}
	return v
}

func main() {
	var err error
	g, err = gocui.NewGui(gocui.Output256)
	if err != nil {
		log.Panicln(err)
	}
	defer g.Close()

	g.Cursor = true
	// g.Mouse = true
	g.Highlight = true
	g.SelFgColor = gocui.Attribute(color.HEX("#f47272").C256().Value())
	g.SetManagerFunc(layout)

	if err := g.SetKeybinding("", gocui.KeyCtrlC, gocui.ModNone, quit); err != nil {
		log.Panicln(err)
	}
	if err := g.SetKeybinding("", gocui.KeyCtrlM, gocui.ModNone, toggleMouse); err != nil {
		log.Panicln(err)
	}
	if err := g.SetKeybinding("todolist", 'q', gocui.ModNone, quit); err != nil {
		log.Panicln(err)
	}
	if err := g.SetKeybinding("", gocui.KeyTab, gocui.ModNone, nextView); err != nil {
		log.Panicln(err)
	}
	if err := g.SetKeybinding("newtodo", gocui.MouseRelease, gocui.ModNone, focusNewtodo); err != nil {
		log.Panicln(err)
	}
	if err := g.SetKeybinding("todolist", gocui.MouseRelease, gocui.ModNone, focusTodolist); err != nil {
		log.Panicln(err)
	}
	if err := g.SetKeybinding("todolist", gocui.KeyArrowDown, gocui.ModNone, todolistDown); err != nil {
		log.Panicln(err)
	}
	if err := g.SetKeybinding("todolist", gocui.KeyArrowUp, gocui.ModNone, todolistUp); err != nil {
		log.Panicln(err)
	}
	if err := g.SetKeybinding("todolist", gocui.KeySpace, gocui.ModNone, todolistComplete); err != nil {
		log.Panicln(err)
	}
	if err := g.SetKeybinding("todolist", gocui.KeyBackspace2, gocui.ModNone, todolistDel); err != nil {
		log.Panicln(err)
	}
	// if err := g.SetKeybinding("", gocui.KeyTab, ModShift, prevView); err != nil {
	// 	log.Panicln(err)
	// }

	if err := g.MainLoop(); err != nil && err != gocui.ErrQuit {
		log.Panicln(err)
	}
}

func toggleMouse(g *gocui.Gui, cur *gocui.View) error {
	g.Mouse = !g.Mouse
	return nil
}

func nextView(g *gocui.Gui, cur *gocui.View) error {
	return gotoView(g, cur, 1)
}

func prevView(g *gocui.Gui, cur *gocui.View) error {
	return gotoView(g, cur, -1)
}

func focusTodolist(g *gocui.Gui, _ *gocui.View) error {
	return focusView(g, "todolist")
}

func focusNewtodo(g *gocui.Gui, v *gocui.View) (err error) {
	if err = focusView(g, "newtodo"); err != nil {
		return
	}

	lines := v.BufferLines()
	// if len(lines) < 2 {
	// 	g.Update(
	// 		func (*gocui.Gui) error {
	// 			return newtodoReset(g, v, true)
	// 		},
	// 	)
	// }
	x, _ := v.Cursor()
	if x > len(lines[1])-1 {
		return v.SetCursor(len(lines[1])-1, 1)
	}
	if x < 1 {
		return v.SetCursor(1, 1)
	}
	return v.SetCursor(x, 1)
}

func focusView(g *gocui.Gui, next string) error {
	if _, err := g.SetCurrentView(next); err != nil {
		return err
	}
	if next == "todolist" {
		g.Cursor = false
	} else {
		g.Cursor = true
	}
	todolist, _ := g.View("todolist")
	todolistRedraw(g, todolist, !g.Cursor)
	return nil
}

func gotoView(g *gocui.Gui, cur *gocui.View, move int) (err error) {
	next := ""
	for i, v := range views {
		if v == cur.Name() {
			next = views[(i+move+len(views)) % len(views)]
		}
	}
	return focusView(g, next)
}

func getActive() int {
	n := 0
	for _, it := range items {
		if !it.complete {
			n += 1
		}
	}
	return n
}

func ItemsLeft(g *gocui.Gui) error {
	maxX, _ := g.Size()
	v, err := g.SetView(
		"itemsleft",
		marginLeft,
		boxItemsleft.top,
		maxX-marginLeft,
		boxItemsleft.top+boxItemsleft.height,
	)
	if err != nil {
		if err != gocui.ErrUnknownView {
			return err
		}
		v.Frame = false
	}

	v.Clear()

	n := getActive()
	plural := "s"
	if n == 1 {
		plural = ""
	}
	fmt.Fprintln(v, color.White.Sprint(n, " item" + plural, " left"))

	return nil
}

// Initialize todolist component
func Todolist(g *gocui.Gui) (*gocui.View, error) {
	maxX, _ := g.Size()
	v, err := g.SetView(
		"todolist",
		marginLeft,
		boxTodolist.top,
		maxX-marginLeft,
		boxTodolist.top+boxTodolist.height,
	)
	if err != nil {
		if err != gocui.ErrUnknownView {
			return nil, err
		}
		v.Autoscroll = true
		return v, todolistRedraw(g, v, false)
	}
	return v, nil
}

func todolistRedraw(g *gocui.Gui, v *gocui.View, isCurrent bool) error {
	v.Clear()

	fmt.Fprintln(v)
	fmt.Fprintln(v)
	for i, item := range items {
		row := " "
		if item.complete {
			row += "[X] "
		} else {
			row += "[ ] "
		}
		row += item.name + "\n"

		if i == todolistIndex && isCurrent {
			row = cSelectedBg.Sprint(row)
		}

		fmt.Fprintln(v, "    " + row)
	}
	return nil
}

func todolistDel(g *gocui.Gui, v *gocui.View) error {
	items = append(items[:todolistIndex], items[todolistIndex+1:]...)
	todolistIndex = (todolistIndex - 1 + len(items)) % len(items)
	return todolistRedraw(g, v, true)
}

func todolistComplete(g *gocui.Gui, v *gocui.View) error {
	if len(items) > 0 {
		items[todolistIndex].complete = !items[todolistIndex].complete
		ItemsLeft(g)
		return todolistRedraw(g, v, true)
	}
	return nil
}

func todolistDown(g *gocui.Gui, v *gocui.View) error {
	return todolistGo(g, v, 1)
}

func todolistUp(g *gocui.Gui, v *gocui.View) error {
	return todolistGo(g, v, -1)
}

func todolistGo(g *gocui.Gui, v *gocui.View, move int) (err error) {
	if len(items) > 0 {
		todolistIndex = (todolistIndex + move + len(items)) % len(items)
		err = todolistRedraw(g, v, true)
	}
	return
}

func newtodoReset(g *gocui.Gui, v *gocui.View, placeholder bool) error {
	paddingLeft := 3

	v.Clear()

	fmt.Fprint(v, strings.Repeat("\n", boxNewtodo.height-1))
	fmt.Fprint(v, strings.Repeat(" ", paddingLeft-1))

	if placeholder {
		fmt.Fprintln(v, cPlaceholder.Sprint("What needs to be done?"))
	}

	g.Cursor = true
	v.SetCursor(1, 1)

	emptyNewtodo = true
	return nil
}

func newtodoEditor (v *gocui.View, key gocui.Key, ch rune, mod gocui.Modifier) {
	todolist := must(g.View("todolist"))
	fmt.Fprintln(todolist, key, ch, mod)

	switch {
	case ch != 0 && mod == 0:
		if emptyNewtodo {
			newtodoReset(g, v, false)
			emptyNewtodo = false
		}
		v.EditWrite(ch)
	case key == gocui.KeySpace:
		if !emptyNewtodo {
			v.EditWrite(' ')
		}
	case key == gocui.KeyEnter:
		if !emptyNewtodo {
			items = append(items, item{name: v.BufferLines()[1], complete: false})
			todolistRedraw(g, todolist, false)
			newtodoReset(g, v, true)
		}

	case key == gocui.KeyBackspace:
		v.EditDelete(false)
	case key == gocui.KeyBackspace2:
		x, _ := v.Cursor()
		if (x > 1) {
			v.EditDelete(true)
		}

	case key == gocui.KeyArrowLeft:
		x, _ := v.Cursor()
		if (x > 1) {
			v.MoveCursor(-1, 0, false)
		}
	case key == gocui.KeyArrowRight:
		v.MoveCursor(1, 0, false)

	case key == gocui.KeyCtrlA:
		if err := v.SetCursor(1, 1); err != nil {
			log.Fatalln(err.Error())
		}
	case key == gocui.KeyCtrlE:
		x := len(v.BufferLines()[1])
		if err := v.SetCursor(x, 1); err != nil {
			log.Fatalln(err.Error())
		}
	}
}

// Initialize newtodo component
func NewTodo(g *gocui.Gui, todolist *gocui.View) error {
	maxX, _ := g.Size()
	v, err := g.SetView(
		"newtodo",
		marginLeft,
		boxNewtodo.top,
		maxX-marginLeft,
		boxNewtodo.top+boxNewtodo.height+1,
	)
	if err != nil {
		if err != gocui.ErrUnknownView {
			return err
		}

		newtodoReset(g, v, true)

		g.SetCurrentView("newtodo")

		v.Editable = true
		v.Editor = gocui.EditorFunc(newtodoEditor)
	}
	return nil
}

func layout(g *gocui.Gui) (err error) {
	var todolist *gocui.View
	if todolist, err = Todolist(g); err != nil {
		return
	}
	if err = ItemsLeft(g); err != nil {
		return
	}
	if err = NewTodo(g, todolist); err != nil {
		return
	}
	return
}

func quit(g *gocui.Gui, v *gocui.View) error {
	return gocui.ErrQuit
}

// TODO
// !1
// X Use tab to go to the todolist and back
// X arrow keys to navigate/select + highlight todo items
// X  space key to mark as completed
// X del to delete
//   e to edit
//  Must scroll when selecting outside of viewport
//
// !2
// Splash screen
// X "X items left"
// Mouse to switch views
// Mouse to edit a todo item
// Display icon for checking off/del clickable with mouse
// Mark all as completed
// Method to auto-scroll the list
//
// !3
// Auto-scrollable todolist
// Clear completed
// Global binding to see all/active/completed
