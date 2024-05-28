use crossterm::{
    event::{self, Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers},
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
    ExecutableCommand,
};
use ratatui::{
    prelude::{CrosstermBackend, Line, Rect, Stylize, Terminal, Style, Modifier, Alignment},
    widgets::{Block, Paragraph, List, ListState, BorderType, Borders, Padding},
};
use std::{
    format,
    io::{stdout, Result, Stdout},
};

// TUI ////////////////////////////////////////////////////////////////
type Tui = Terminal<CrosstermBackend<Stdout>>;

fn tui_init() -> Result<Tui> {
    stdout().execute(EnterAlternateScreen)?;
    enable_raw_mode()?;
    Terminal::new(CrosstermBackend::new(stdout()))
}

fn tui_done() -> Result<()> {
    stdout().execute(LeaveAlternateScreen)?;
    disable_raw_mode()?;
    Ok(())
}

// todos //////////////////////////////////////////////////////////////
#[derive(Debug)]
struct Todo {
    name: String,
    complete: bool,
}

type Todos = Vec<Todo>;

fn new_todo(name: String) -> Todo {
    return Todo{ name, complete: false };
}

fn new_todolist() -> Todos {
    Vec::new()
}

fn fmt_itemsleft(ts: &Todos) -> String {
    let mut n = 0;
    for t in ts {
        if !t.complete {
            n += 1;
        }
    }
    format!("{} item{} left", n, (if n == 1 { "" } else { "s" }))
}

fn complete_all(ts: &mut Todos) {
    for t in ts {
        t.complete = true
    }
}

fn clear_completed(ts: Todos) -> Todos {
    let mut new_items: Todos = Vec::new();
    for t in ts {
        if !t.complete {
            new_items.push(t);
        }
    }
    new_items
}

fn show(ts: &Todos) {
    for i in ts {
        println!("- {}", i.fmt_item());
    }
    println!("{}", fmt_itemsleft(ts));
}

impl Todo {
    fn toggle(&mut self) {
        self.complete = !self.complete;
    }
    
    fn fmt_item(&self) -> String {
        (if self.complete { "(X) " } else { "( ) " }).to_string() + &self.name
    }
}


// App ////////////////////////////////////////////////////////////////
#[derive(Debug, Default)]
struct App {
    exit: bool,
    todolist: Todos,
    focus: Focus,
    message: String,
}

#[derive(Debug, PartialEq, Default)]
enum Focus {
    #[default]
    Input,
    List,
}

impl App {
    fn run(&mut self, terminal: &mut Tui) -> Result<()> {
        self.focus = Focus::Input;
        self.message = "hello!".to_string();

        self.todolist = new_todolist();
        self.todolist.push(new_todo("1".to_string()));
        self.todolist.push(new_todo("2".to_string()));
        self.todolist.push(new_todo("3".to_string()));
        self.todolist.push(new_todo("4".to_string()));

        let mut liststate = ListState::default();

        let list = self.todolist.iter().map(|t| t.fmt_item()).collect::<List>()
            .block(Block::bordered()
                   .border_type(BorderType::Rounded)
                   .padding(Padding::symmetric(3, 1)))
            .highlight_style(Style::new().add_modifier(Modifier::REVERSED))
            .repeat_highlight_symbol(true);

        let margin_side = 30;
        let list_top = 12;
        let list_bot = 4;

        let header = Paragraph::new("T O D O M V C")
                        .alignment(Alignment::Center);
        let input = Block::new()
                        .border_type(BorderType::Rounded)
                        .borders(Borders::ALL)
                        .padding(Padding::horizontal(1));

        while !self.exit {
            terminal.draw(|frame| {
                let full = frame.size();
                let header_area = Rect::new(0, 5, full.width - 1, 1);
                let input_area = Rect::new(
                    margin_side,
                    9,
                    full.width - margin_side - margin_side,
                    3
                );

                frame.render_widget(&header, header_area);
                frame.render_widget(&input, input_area);

                frame.render_stateful_widget(
                    &list,
                    Rect::new(
                        margin_side,
                        list_top,
                        full.width - margin_side - margin_side,
                        full.height - list_top - list_bot
                    ),
                    &mut liststate
                );

                frame.render_widget(
                    Paragraph::new(self.message.clone()),
                    Rect::new(0, full.height - 1, full.width - 1, 1)
                );
            })?;

            match event::read()? {
                Event::Key(key_event) => self.handle_key(key_event, &mut liststate),
                _ => {}
            };
        }
        Ok(())
    }

    fn handle_key(&mut self, key: KeyEvent, state: &mut ListState) {
        if key.kind == KeyEventKind::Press {
            if key.code == KeyCode::Char('c') && key.modifiers == KeyModifiers::CONTROL {
                self.exit = true;
            } else if key.modifiers != KeyModifiers::NONE {
                return;
            }

            if key.code == KeyCode::Tab {
                if self.focus == Focus::Input {
                    self.focus = Focus::List;
                    self.message = "list".to_string();
                } else {
                    self.focus = Focus::Input;
                    self.message = "input".to_string();
                }
                return;
            }

            // Input
            if self.focus == Focus::Input {
                self.message = "key while focus on input".to_string();
                return;
            }

            // Todolist
            let len = self.todolist.len();
            if len == 0 {
                return;
            }
            if key.code == KeyCode::Down {
                if let Some(sel) = state.selected() {
                    state.select(Some((sel + 1) % len));
                } else {
                    state.select(Some(0));
                }
            } else if key.code == KeyCode::Up {
                if let Some(sel) = state.selected() {
                    state.select(Some(if sel == 0 { len - 1 } else { sel - 1 }));
                } else {
                    state.select(Some(len - 1));
                }
            }
        }
    }
}

// main ///////////////////////////////////////////////////////////////
fn main() -> Result<()> {
    let mut terminal = tui_init()?;
    let app_result = App::default().run(&mut terminal);
    tui_done()?;
    app_result
}
