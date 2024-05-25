package main

import (
	"fmt"

	"github.com/gdamore/tcell/v2"
	"github.com/rivo/tview"
)

type item struct {
	name string
	complete bool
}

var items []*item

func fmtItem(it *item) (s string) {
	if it.complete {
		s = "(X)"
	} else {
		s = "( )"
	}
	s += fmt.Sprintf("  %s", it.name)
	return
}

func fmtItemsleft() (s string) {
	n := 0
	for _, it := range items {
		if !it.complete {
			n += 1
		}
	}
	if n == 0 {
		return "No todos, woohoo!"
	}

	if n == 1 {
		s = "item left"
	} else {
		s = "items left"
	}
	return fmt.Sprintf("%d %s", n, s)
}

func markAllComplete(todolist *tview.List, itemsleft *tview.TextView) {
	if len(items) == 0 {
		return
	}
	for i, it := range items {
		it.complete = true
		todolist.SetItemText(i, fmtItem(it), "")
	}
	itemsleft.SetText(fmtItemsleft())
}

func makeEditForm(i int, done func()) (form *tview.Form) {
	oldName := items[i].name
	form = tview.NewForm().
		AddInputField("New name", oldName, 40, tview.InputFieldMaxLength(40), func(newName string) {
			items[i].name = newName
		}).
		AddButton("Cancel", func() {
			items[i].name = oldName
			done()
		}).
		SetButtonStyle(tcell.Style{}.Background(tcell.ColorDarkBlue)).
		AddButton("Done", done).
		SetButtonsAlign(tview.AlignCenter)
	form.SetBorder(true).SetBorderPadding(1, 1, 1, 1)
	return
}

func makeCenteredModal(item tview.Primitive, height int, width int) (modal *tview.Flex) {
	modal = tview.NewFlex().
		AddItem(nil, 0, 1, false).
		AddItem(tview.NewFlex().SetDirection(tview.FlexRow).
			AddItem(nil, 0, 1, false).
			AddItem(item, height, 1, true).
			AddItem(nil, 0, 1, false), width, 1, true).
		AddItem(nil, 0, 1, false)
	return
}

func main() {
	app := tview.NewApplication().EnableMouse(true)

	makeFiller := func(text string, border bool) *tview.Box {
		return tview.NewBox().SetTitle(text).SetTitleAlign(tview.AlignCenter).SetBorder(border)
	}
	menu := makeFiller("Menu", false)
	sideBar := makeFiller("Side Bar", false)

	header := tview.NewTextView().SetText("T O D O M V C").SetTextAlign(tview.AlignCenter)
	header.SetBorderPadding(4, 0, 0, 0)

	footer := tview.NewTextView().SetText("ctrl+c to quit").
		SetTextAlign(tview.AlignLeft).SetTextColor(tcell.ColorLightGray)
	footer.SetBorderPadding(1, 0, 3, 0)

	main := tview.NewFlex().SetDirection(tview.FlexRow)

	var pages *tview.Pages

	todolist := tview.NewList()
	newtodo := tview.NewInputField()
	itemsleft := tview.NewTextView().SetText("").SetTextAlign(tview.AlignRight)

	todolist.SetSelectedFunc(func(index int, mainText string, secondaryText string, shortcut rune) {
		// TODO: Wrap mouse handler to prevent making complete on mouse click
		it := items[index]
		it.complete = !it.complete
		todolist.SetItemText(index, fmtItem(it), "")
		itemsleft.SetText(fmtItemsleft())
	}).
		SetSelectedStyle(tcell.Style{}.Background(tcell.ColorDimGray).Foreground(tcell.ColorWhite)).
		SetSelectedFocusOnly(true)
	todolist.SetBorder(true).SetBorderPadding(1, 1, 2, 2)

	todolist.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		switch {
		case event.Key() == tcell.KeyTab:
			app.SetFocus(newtodo)
		case event.Rune() == 'e':
			i := todolist.GetCurrentItem()
			form := makeEditForm(i, func() {
				pages.SwitchToPage("main")
				pages.RemovePage("edititem")
				todolist.SetItemText(i, fmtItem(items[i]), "")
			})
			editModal := makeCenteredModal(form, 7, 60)
			pages.AddPage("edititem", editModal, true, true)
		}
		return event
	})

	newtodo.SetFieldBackgroundColor(tcell.ColorBlack).
		SetFieldWidth(30).
		SetPlaceholder("What needs to be done?").
		SetPlaceholderStyle(
			tcell.Style{}.Background(tcell.ColorBlack).Foreground(tcell.ColorGray),
		).
		SetAcceptanceFunc(tview.InputFieldMaxLength(50))

	newtodo.SetDoneFunc(func(key tcell.Key) {
		switch key {
		case tcell.KeyEnter:
			newItem := &item{name: newtodo.GetText(), complete: false}
			items = append(items, newItem)
			todolist.AddItem(fmtItem(newItem), "", 0, nil)
			todolist.SetCurrentItem(-1)
			itemsleft.SetText(fmtItemsleft())
			newtodo.SetText("")
		case tcell.KeyTab:
			app.SetFocus(todolist)
		}
	}).SetBorderPadding(1, 1, 2, 2).SetBorder(true).SetBorderColor(tcell.ColorWhite)

	completeAllLabel := " Mark all as complete "
	completeAll := tview.NewButton(completeAllLabel).SetSelectedFunc(func() {
		markAllComplete(todolist, itemsleft)
	})
	completeAll.SetStyle(tcell.Style{}.Background(tcell.ColorDarkGoldenrod))
	completeAll.SetActivatedStyle(tcell.Style{}.Background(tcell.ColorDarkMagenta))

	clearCompletedLabel := " Clear completed "
	clearCompleted := tview.NewButton(clearCompletedLabel).SetSelectedFunc(func() {
		var newItems []*item
		o := 0
		for i, it := range items {
			if it.complete {
				todolist.RemoveItem(i-o)
				o += 1
			} else {
				newItems = append(newItems, it)
			}
		}
		items = newItems
		itemsleft.SetText(fmtItemsleft())
	})
	clearCompleted.SetStyle(tcell.Style{}.Background(tcell.ColorDarkGreen))
	clearCompleted.SetActivatedStyle(tcell.Style{}.Background(tcell.ColorDarkMagenta))

	// TODO: Add "show only active/completed"
	// use a grid to align this row with itemsleft instead
	bottomRow := tview.NewFlex().SetDirection(tview.FlexColumn).
		AddItem(completeAll, len(completeAllLabel), 1, false).
		AddItem(nil, 1, 1, false).
		AddItem(clearCompleted, len(clearCompletedLabel), 1, false)

	main.AddItem(newtodo, 5, 1, true).
		AddItem(bottomRow, 1, 1, false).
		AddItem(todolist, 0, 2, false).
		AddItem(itemsleft, 1, 1, false)

	grid := tview.NewGrid().
		SetRows(6, 0, 3).
		SetColumns(20, 0, 20).
		SetBorders(false).
		AddItem(header, 0, 0, 1, 3, 0, 0, false).
		AddItem(footer, 2, 0, 1, 3, 0, 0, false).
		AddItem(menu,   1, 0, 1, 1, 0, 10, false).
		AddItem(main,    1, 1, 1, 1, 0, 100, true).
		AddItem(sideBar, 1, 2, 1, 1, 0, 10, false)

	pages = tview.NewPages().
		AddPage("main", grid, true, true)

	if err := app.SetRoot(pages, true).SetFocus(grid).Run(); err != nil {
		panic(err)
	}
}
