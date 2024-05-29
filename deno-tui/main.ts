import { crayon } from "crayon/mod.ts";
import { Input, Text, Table } from "tui/src/components/mod.ts";
import { Theme, Tui, handleInput, handleKeyboardControls, handleMouseControls } from "tui/mod.ts";
import { Signal } from "tui/mod.ts";


const tui = new Tui({
  style: crayon.bgBlack, // Make background black
  refreshRate: 1000 / 60, // Run in 60FPS
});

tui.dispatch(); // Close Tui on CTRL+C

handleInput(tui);
handleMouseControls(tui);
handleKeyboardControls(tui);

const baseTheme: Theme = {
  base: crayon.white,
  focused: crayon.bgLightBlue,
  active: crayon.bgLightBlack,
  disabled: crayon.bgLightBlack.black,
};

const cursorBaseTheme = {
  ...baseTheme,
  cursor: { base: crayon.invert },
};

const newtodo_value = new Signal("");

const newtodo = new Input({
  parent: tui,
  placeholder: "What needs to be done?",
  theme: cursorBaseTheme,
  rectangle: {
    column: 10,
    row: 10,
    width: 80,
  },
  zIndex: 0,
  text: newtodo_value,
});

const message = new Signal("hello");
const message_line = new Text({
  parent: tui,
  text: message,
  theme: baseTheme,
  rectangle: {
    column: 1,
    row: 1,
  },
  zIndex: 1,
})

newtodo.on("keyPress", ({key, ctrl, meta}) => {
  if (key.toString() == "return") {
    if (newtodo.text.peek().length > 0) {
      todolist.data.value.push(["( )", newtodo.text.peek()]);
      newtodo.text.value = "";
      newtodo.cursorPosition.value = 0;
    }
  } else if (ctrl && key == "a") {
    newtodo.cursorPosition.value = 0;
  } else if (ctrl && key == "e") {
    newtodo.cursorPosition.value = newtodo.text.peek().length;
  }
})

const items = new Signal([["( )", "tada"]]);
const todolist = new Table({
  parent: tui,
  data: [["( )", "tada"]],
  theme: {
    base: crayon.white,
    frame: { base: crayon.bgBlack },
    selectedRow: {
      base: crayon.bold.bgBlue.white,
      focused: crayon.bold.bgLightBlue.white,
      active: crayon.bold.bgMagenta.black,
    },
    header: { base: crayon.bgBlack.bold.lightBlue },
  },
  headers: [{title: "a", width: 5}, { title: "b", width: 60}],
  rectangle: {
    column: 10,
    row: 12,
    height: 20,
  },
  zIndex: 0,
  charMap: "rounded",
})

tui.run();
