use crossterm::{
    event::{self, Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers},
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
    ExecutableCommand,
};
use ratatui::{
    prelude::{Alignment, Color, CrosstermBackend, Line, Rect, Style, Stylize, Terminal},
    widgets::{Block, BorderType, List, ListState, Padding, Paragraph},
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

impl Todo {
    fn new(name: String) -> Self {
        Self {
            name,
            complete: false,
        }
    }

    fn toggle(&mut self) {
        self.complete = !self.complete;
    }

    fn fmt_item(&self) -> String {
        let middle = (if self.complete { "(X) " } else { "( ) " }).to_string() + &self.name;
        format!("\n   {middle}\n\n")
    }
}

type Todos = Vec<Todo>;

fn fmt_itemsleft(ts: &Todos) -> String {
    let n = ts.iter().filter(|t| !t.complete).count();
    match n {
        0 => "woohoo! all done".to_string(),
        1 => "1 item left".to_string(),
        _ => format!("{} item{} left", n, (if n == 1 { "" } else { "s" }))
    }
}

fn complete_all(ts: &mut Todos) {
    for t in ts {
        t.complete = true
    }
}

// Input //////////////////////////////////////////////////////////////
#[derive(Debug)]
struct Inputter {
    input: String,
    cursor: usize,
    saved_input: String,
    saved_cursor: usize,
}

impl Inputter {
    fn new() -> Self {
        Self {
            input: String::new(),
            cursor: 0,
            saved_input: String::new(),
            saved_cursor: 0,
        }
    }

    /// Save current input and cursor position.
    fn save(&mut self) {
        self.saved_cursor = self.cursor;
        self.saved_input = self.input.clone();
    }

    /// Restore saved input and cursor position.
    fn restore(&mut self) {
        self.cursor = self.saved_cursor;
        self.input = self.saved_input.clone();
    }

    /// Byte index of current cursor position.
    fn byte_index(&self) -> usize {
        self.input
            .char_indices()
            .map(|(i, _)| i)
            .nth(self.cursor)
            .unwrap_or(self.input.len())
    }

    fn clamp(&mut self, idx: usize) -> usize {
        idx.clamp(0, self.input.chars().count())
    }

    fn right(&mut self) {
        self.cursor = self.clamp(self.cursor + 1);
    }

    fn left(&mut self) {
        self.cursor = self.clamp(self.cursor - 1);
    }

    /// Clear input and reset cursor to 0.
    fn reset(&mut self) {
        self.cursor = 0;
        self.input.clear();
    }

    /// Insert a new character at cursor position.
    fn insert(&mut self, c: char) {
        let index = self.byte_index();
        self.input.insert(index, c);
        self.right();
    }

    /// Delete left or right a character a cursor position.
    fn delete(&mut self, right: bool) {
        if !right {
            if self.cursor == 0 {
                return;
            }
            let cur = self.cursor;
            // 0 1 2 3 |4| 5 6
            // 0 1 2   |4| 5 6
            let before = self.input.chars().take(cur - 1);
            let after = self.input.chars().skip(cur);

            // Put all characters together except the selected one.
            // By leaving the selected one out, it is forgotten and therefore deleted.
            self.input = before.chain(after).collect();
            self.left();
        } else {
            let cur = self.byte_index();
            // 0 1 2 3 |4| 5 6
            // 0 1 2 3 |   5 6
            let before = self.input.chars().take(cur);
            let after = self.input.chars().skip(cur + 1);

            self.input = before.chain(after).collect();
        }
    }
}

// App ////////////////////////////////////////////////////////////////
#[derive(Debug)]
struct App {
    exit: bool,
    todolist: Todos,
    focus: Focus,
    inputter: Inputter,
    first_todo: bool,
    editing: Option<usize>,
}

#[derive(Debug, PartialEq, Default)]
enum Focus {
    #[default]
    Input,
    List,
}

impl App {
    fn new() -> Self {
        Self {
            exit: false,
            todolist: Vec::new(),
            focus: Focus::Input,
            inputter: Inputter::new(),
            first_todo: true,
            editing: None,
        }
    }

    fn focus_border(&self, check_focus: Focus) -> Style {
        if self.focus == check_focus {
            if self.focus == Focus::Input {
                if let Some(_) = self.editing {
                    return Style::new().yellow();
                }
            }
            return Style::new().blue();
        }
        Style::new()
    }

    fn run(&mut self, terminal: &mut Tui) -> Result<()> {
        terminal.show_cursor()?;

        let mut liststate = ListState::default();

        let margin_side = 30;
        let list_top = 13;
        let list_bot = 4;

        let header = Paragraph::new("T O D O M V C").alignment(Alignment::Center);

        let complete_all = Paragraph::new(Line::from(vec![
            " (M)".bold(),                  // 4
            " Mark all as complete".into(), // 21
        ]));
        let clear_completed = Paragraph::new(Line::from(vec![
            "(C)".bold(),              // 3
            " Clear completed".into(), // 16
        ]));

        let bindings = [
            ("tab", "switch focus"),
            ("arrows", "navigate list"),
            ("space/enter", "toggle complete"),
        ];
        let mut bindings_line = vec!["ctrl-c".bold(), ": quit".into()];
        for pair in bindings {
            bindings_line.push(", ".into());
            bindings_line.push(pair.0.bold());
            bindings_line.push(": ".into());
            bindings_line.push(pair.1.into());
        }
        let bindings_widget =
            Paragraph::new(Line::from(bindings_line)).alignment(Alignment::Center);

        // Main loop
        while !self.exit {
            terminal.draw(|frame| {
                let full = frame.size();
                let width = full.width - margin_side - margin_side;

                // Header
                frame.render_widget(&header, Rect::new(0, 5, full.width - 1, 1));

                // Input
                frame.render_widget(
                    Paragraph::new(self.inputter.input.clone()).block(
                        Block::bordered()
                            .border_type(BorderType::Rounded)
                            .padding(Padding::horizontal(1))
                            .border_style(self.focus_border(Focus::Input)),
                    ),
                    Rect::new(margin_side, 9, width, 3),
                );
                if self.focus == Focus::Input {
                    // Cursor position in input
                    frame.set_cursor(
                        margin_side + 2 + u16::try_from(self.inputter.cursor).unwrap(),
                        10,
                    );
                }

                // Buttons
                frame.render_widget(
                    &complete_all,
                    Rect::new(margin_side, list_top - 1, 21 + 5, 1)
                );
                frame.render_widget(
                    &clear_completed,
                    Rect::new(margin_side + 21 + 6, list_top - 1, 16 + 4, 1)
                );

                // Todolist
                let list = self
                    .todolist
                    .iter()
                    .map(|t| t.fmt_item())
                    .collect::<List>()
                    .block(
                        Block::bordered()
                            .border_type(BorderType::Rounded)
                            .border_style(self.focus_border(Focus::List)),
                    )
                    .highlight_style(Style::default().white().bg(Color::Rgb(65, 70, 80)));

                frame.render_stateful_widget(
                    &list,
                    Rect::new(
                        margin_side,
                        list_top,
                        width,
                        full.height - list_top - list_bot,
                    ),
                    &mut liststate,
                );

                // Itemsleft
                frame.render_widget(
                    Paragraph::new(
                        if self.first_todo { String::new() } else { fmt_itemsleft(&self.todolist) }
                    ).alignment(Alignment::Right),
                    Rect::new(margin_side, full.height - list_bot, width, 1),
                );

                // Bindings hint
                frame.render_widget(
                    &bindings_widget,
                    Rect::new(0, full.height - 1, full.width - 1, 1),
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
                return;
            } else if key.modifiers != KeyModifiers::NONE {
                return;
            }

            if key.code == KeyCode::Tab {
                if self.focus == Focus::Input {
                    self.focus = Focus::List;
                } else {
                    self.focus = Focus::Input;
                }
                return;
            }

            // Input
            if self.focus == Focus::Input {
                match key.code {
                    KeyCode::Char(c) => {
                        self.inputter.insert(c);
                    }
                    KeyCode::Left => {
                        self.inputter.left();
                    }
                    KeyCode::Right => {
                        self.inputter.right();
                    }
                    KeyCode::Backspace => {
                        self.inputter.delete(false);
                    }
                    KeyCode::Delete => {
                        self.inputter.delete(true);
                    }
                    KeyCode::Enter => {
                        let name = self.inputter.input.clone();
                        if !name.is_empty() {
                            if let Some(idx) = self.editing {
                                // Finish editing
                                self.todolist[idx].name = name;
                                self.focus = Focus::List;
                                self.editing = None;
                                self.inputter.restore();
                            } else {
                                // New item
                                self.todolist.push(Todo::new(name));
                                state.select(Some(self.todolist.len() - 1));
                                self.first_todo = false;
                                self.inputter.reset();
                            }
                        }
                    }
                    KeyCode::Esc => {
                        if let Some(_) = self.editing {
                            self.editing = None;
                            self.focus = Focus::List;
                        }
                    }
                    _ => {}
                }

                return;
            }

            // Todolist
            let len = self.todolist.len();
            if len == 0 {
                return;
            }
            if key.code == KeyCode::Down || key.code == KeyCode::Char('j') {
                if let Some(sel) = state.selected() {
                    if sel + 1 != len {
                        state.select(Some(sel + 1));
                    }
                } else {
                    state.select(Some(0));
                }
            } else if key.code == KeyCode::Up || key.code == KeyCode::Char('k') {
                if let Some(sel) = state.selected() {
                    if sel != 0 {
                        state.select(Some(sel - 1));
                    }
                } else {
                    state.select(Some(len - 1));
                }
            } else if key.code == KeyCode::Enter || key.code == KeyCode::Char(' ') {
                if let Some(sel) = state.selected() {
                    self.todolist[sel].toggle();
                } else {
                }
            } else if key.code == KeyCode::Char('e') {
                if let Some(current) = state.selected() {
                    self.editing = Some(current);
                    self.inputter.save();

                    self.inputter.input = self.todolist[current].name.clone();
                    self.inputter.cursor = self.inputter.input.chars().count();
                    self.focus = Focus::Input;
                }
            } else if key.code == KeyCode::Char('m') {
                complete_all(&mut self.todolist);
            } else if key.code == KeyCode::Char('c') {
                let mut new_list = Vec::new();
                // Save current selection, if current item is not cleared.
                let sel = match state.selected() {
                    None => self.todolist.len(),
                    Some(i) => i,
                };
                let mut new_sel = sel;
                let mut sel_cleared = true;

                for (i, t) in self.todolist.iter().enumerate() {
                    if !t.complete {
                        new_list.push(Todo { name: t.name.clone(), complete: t.complete });
                        if i == sel {
                            sel_cleared = false;
                        }
                    } else {
                        if i < sel {
                            new_sel -= 1;
                        }
                    }
                }
                self.todolist = new_list;
                state.select(if !sel_cleared { Some(new_sel) } else { None });
            }
        }
    }
}

// main ///////////////////////////////////////////////////////////////
fn main() -> Result<()> {
    let mut terminal = tui_init()?;
    let app_result = App::new().run(&mut terminal);
    tui_done()?;
    app_result
}
