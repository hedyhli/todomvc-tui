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
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
use zi_term::Result;
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
        let sides = 25;
        Container::new(FlexDirection::Row, [
            Item::fixed(sides)(Text::with(TextProperties::new())),
            Item::auto(
                Container::new(FlexDirection::Column, [
                Item::auto(
                    Text::with(TextProperties::new()
                        .align(TextAlign::Centre)
                        // .style(Style::default())
                        .content(String::from("header"))
                    )
                ),
                Item::auto(
                    Border::with(BorderProperties::new(||
                        Text::with(TextProperties::new()
                            .align(TextAlign::Left)
                            .style(Style::default())
                            .content(String::from(" Input here"))
                        )
                ))
                ),
                Item::auto(Text::with(TextProperties::new())),
                Item::fixed(19)(
                    Border::with(BorderProperties::new(||
                        Text::with(TextProperties::new()
                            .align(TextAlign::Left)
                            .style(Style::default())
                            .content(String::from("List here"))
                        )))
                ),
                Item::fixed(1)(
                    Text::with(TextProperties::new()
                        .align(TextAlign::Right)
                        .style(Style::default())
                        .content(String::from("items left")))
                ),
                Item::auto(Text::with(TextProperties::new().content("hi"))),
            ])),
            Item::fixed(sides)(Text::with(TextProperties::new())),
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
