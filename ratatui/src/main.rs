use crossterm::{
    event::{self, KeyCode, KeyEvent, Event, KeyEventKind, KeyModifiers},
    terminal::{
        disable_raw_mode, enable_raw_mode, EnterAlternateScreen,
        LeaveAlternateScreen,
    },
    ExecutableCommand,
};
use ratatui::{
    prelude::{CrosstermBackend, Stylize, Terminal, Rect, Line, Frame},
    widgets::Paragraph,
};
use std::{io::{stdout, Result, Stdout}, format};

type Tui = Terminal<CrosstermBackend<Stdout>>;

#[derive(Debug, Default)]
struct App {
    keys: Vec<KeyEvent>,
    exit: bool,
}

fn init() -> Result<Tui> {
    stdout().execute(EnterAlternateScreen)?;
    enable_raw_mode()?;
    Terminal::new(CrosstermBackend::new(stdout()))
}

fn done() -> Result<()> {
    stdout().execute(LeaveAlternateScreen)?;
    disable_raw_mode()?;
    Ok(())
}

impl App {
    fn run(&mut self, terminal: &mut Tui) -> Result<()> {
        while !self.exit {
            terminal.draw(|frame| self.render(frame))?;
            // Rather than event::poll, this blocks until there is an event.
            // Avoids redrawing the terminal constantly.
            match event::read()? {
                Event::Key(key_event) => {
                    self.handle_key(key_event)
                }
                _ => {}
            };
        }
        Ok(())
    }

    fn render(&self, frame: &mut Frame) {
        frame.render_widget(
            Paragraph::new(Line::from(vec![
                "Hello ratatui! Press".into(),
                " q".green(),
                " or".into(),
                " ctrl".green(),
                "+".into(),
                "c".green(),
                " to quit.".into(),
            ])),
            Rect::new(1, 1, 60, 2),
        );
        frame.render_widget(
            Paragraph::new("Press any key combinations to see the key ...object?"),
            Rect::new(1, 2, 60, 2),
        );

        // XXX: This does not account for max height.
        let start_line = 4;
        for (i, key) in self.keys.iter().enumerate() {
            frame.render_widget(
                Paragraph::new(Line::from(vec![
                    "code: ".into(),
                    format!("{:?}", key.code).green(),
                    ", mod: ".into(),
                    format!("{:?}", key.modifiers).red(),
                    ", kind: ".into(),
                    format!("{:?}", key.kind).blue(),
                ])),
                Rect::new(1, (start_line + i).try_into().unwrap(), 80, 2),
            );
        }
    }

    fn handle_key(&mut self, key: KeyEvent) {
        self.keys.push(key);
        if key.kind == KeyEventKind::Press {
            if key.code == KeyCode::Char('q') {
                self.exit = true;
            }
            if key.code == KeyCode::Char('c') && key.modifiers == KeyModifiers::CONTROL {
                self.exit = true;
            }
        }
    }
}

fn main() -> Result<()> {
    let mut terminal = init()?;
    let app_result = App::default().run(&mut terminal);
    done()?;
    app_result
}
