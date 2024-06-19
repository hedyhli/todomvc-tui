package main

import "core:encoding/ansi"
import "core:fmt"
import "core:strings"

Palette := map[string]string {
	"red"     = ansi.FG_RED, // Focused border
	"bg-grey" = ansi.BG_BRIGHT_BLACK, // Selection
	"italic"  = ansi.ITALIC,
	"grey"    = ansi.FG_BRIGHT_BLACK, // Placeholder
}

colored :: proc(text: string, attrs: ..string) -> (result: string) {
	result = ""
	for attr in attrs {
		result = strings.concatenate({result, ansi.CSI, Palette[attr], ansi.SGR})
	}
	result = strings.concatenate({result, text, ansi.CSI + ansi.RESET + ansi.SGR})
	return
}

main :: proc() {
	fmted: string
	fmted = colored("Placeholder", "grey", "italic")
	defer delete(fmted)

	fmt.println("Normal")
	fmt.println(fmted)
	fmted = colored("Focused border", "red")
	fmt.println(fmted)
	fmted = colored("Selection", "bg-grey")
	fmt.println(fmted)
}
