package main

import (
	"strings"
	"git.sr.ht/~rockorager/vaxis"
	"git.sr.ht/~rockorager/vaxis/widgets/textinput"
)

var wordList = "foo,bar,baz"

func main() {
	vx, err := vaxis.New(vaxis.Options{})
	if err != nil {
		panic(err)
	}
	defer vx.Close()

	words := strings.Split(wordList, ",")

	complete := func(input string) []string {
		i := strings.LastIndex(input, " ")

		lastWord := input
		if i > 0 {
			lastWord = input[i+1:]
		}
		lower := strings.ToLower(lastWord)
		res := make([]string, 0, len(wordList))
		trimmed := strings.TrimSuffix(input, lastWord)
		for _, word := range words {
			if strings.HasPrefix(word, lower) {
				res = append(res, trimmed+word)
			}
		}
		return res
	}
	ti := textinput.NewMenuComplete(complete)
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
		ti.Draw(vx.Window())
		vx.Render()
	}
}
