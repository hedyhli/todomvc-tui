// use unicode_width::UnicodeWidthStr;

use zi::{
    components::{
        // input::{Cursor, Input, InputChange, InputProperties, InputStyle},
        // select::{Select, SelectProperties},
        text::{Text, TextAlign, TextProperties},
        border::{Border, BorderProperties},
    },
    prelude::*,
};
use zi_term::Result;

#[derive(Default, Debug)]
enum Focus {
    #[default]
    Input,
    List,
}

#[derive(Debug)]
struct Todo {
    name: String,
    complete: bool,
}

impl Todo {
    fn new(name: String) -> Self {
        Self { name, complete: false }
    }

    fn toggle(&mut self) {
        self.complete = !self.complete;
    }

    fn fmt(&self) -> String {
        format!("{} {}", (if self.complete { "(X)" } else { "( )" }), self.name)
    }
}

#[derive(Debug)]
struct Todolist {
    /// The actual list
    l: Vec<Todo>,
    cur: usize,
}

impl Todolist {
    fn new() -> Self {
        Self { l: Vec::new(), cur: 0 }
    }

    fn itemsleft(&self) -> String {
        let left = self.l.iter().filter(|it| !it.complete).count();
        match left {
            0 => "woohoo! nothing left!".to_string(),
            1 => "1 item left".to_string(),
            _ => format!("{left} items left")
        }
    }
}

#[derive(Debug)]
struct App {
    focus: Focus,
    list: Todolist,
    link: ComponentLink<Self>,
}

enum AppMsg {
    Lolwut
}

impl Component for App {
    type Message = AppMsg;
    type Properties = ();

    fn create(_p: Self::Properties, _f: Rect, link: ComponentLink<Self>,) -> Self {
        Self { focus: Focus::default(), list: Todolist::new(), link }
    }

    fn view(&self) -> Layout {
        Container::new(FlexDirection::Column, [
            Item::fixed(9)(Text::with(TextProperties::new()
                .align(TextAlign::Centre)
                .content(String::from("Hi")),
            )),
            Item::fixed(3)(Text::with(TextProperties::new()
                .align(TextAlign::Centre)
                .content(String::from("Hi")),
            ))
        ]).into()
    }

    fn update(&mut self, _: Self::Message) -> ShouldRender {
        ShouldRender::Yes
    }

    fn bindings(&self, bindings: &mut Bindings<Self>) {
        if !bindings.is_empty() {
            return;
        }
        bindings.set_focus(true);
        bindings.add("exit", [Key::Ctrl('c')], |this: &Self| this.link.exit());
    }
}

fn main() -> Result<()> {
    zi_term::incremental()?.run_event_loop(App::with(()))
}
