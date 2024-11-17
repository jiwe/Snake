use crossterm::event::*;
use crossterm::terminal::ClearType;
use crossterm::{cursor, event, execute, queue, terminal};
use std::io::stdout;
use std::time::Duration;

struct CleanUp;

impl Drop for CleanUp {
    fn drop(&mut self) {
        terminal::disable_raw_mode().expect("Unable to disable raw mode")
    }
}

struct Snake {
    body: Vec<(usize, usize)>,
    direction: KeyCode,
}

impl Snake {
    fn new(body: Vec<(usize, usize)>, direction: KeyCode) -> Snake {
        Snake { body, direction }
    }

    fn take_step(&mut self, position: (usize, usize)) {
        self.body.remove(0);
        self.body.push(position);
    }

    fn set_direction(&mut self, direction: KeyCode) {
        self.direction = direction;
    }

    fn head(&self) -> (usize, usize) {
        *self.body.last().unwrap()
    }
}

struct Apple;

struct Game {
    height: usize,
    width: usize,
    snake: Snake,
}

impl Game {
    fn new(height: usize, width: usize) -> Game {
        Game {
            height,
            width,
            snake: Snake::new(vec![(2, 2), (2, 3), (3, 3), (4, 3)], KeyCode::Up),
        }
    }

    fn board_matrix(&self) -> Vec<Vec<usize>> {
        vec![vec![0; self.width]; self.height]
    }

    fn render(&self) {
        let matrix = self.board_matrix();

        for (i, row) in matrix.iter().enumerate() {
            for (j, element) in row.iter().enumerate() {
                if j == 0 && (i != 0 || i != matrix.len() - 1) {
                    print!("\r\n");
                }

                if (i == 0 && j == 0)
                    || (i == 0 && j == row.len() - 1)
                    || (i == matrix.len() - 1 && j == 0)
                    || (i == matrix.len() - 1 && j == row.len() - 1)
                {
                    print!("+");
                } else if i == 0 || i == matrix.len() - 1 {
                    print!("-");
                } else if j == 0 || j == row.len() - 1 {
                    print!("|");
                } else if self.snake.body.contains(&(i, j)) {
                    if (i, j) != self.snake.head() {
                        print!("O");
                    } else {
                        print!("X");
                    }
                } else if *element == 0 {
                    print!(" ");
                }
            }
        }
    }

    fn read_key(&self) -> std::io::Result<KeyEvent> {
        loop {
            if event::poll(Duration::from_millis(500))? {
                if let Event::Key(event) = event::read()? {
                    return Ok(event);
                }
            }
        }
    }

    fn process_keypress(&mut self) -> std::io::Result<u32> {
        match self.read_key()? {
            KeyEvent {
                code: KeyCode::Char('q'),
                modifiers: KeyModifiers::CONTROL,
                kind: _,
                state: _,
            } => return Ok(1),
            KeyEvent {
                code: direction @ (KeyCode::Up | KeyCode::Down | KeyCode::Left | KeyCode::Right),
                modifiers: KeyModifiers::NONE,
                kind: _,
                state: _,
            } => {
                self.snake.set_direction(direction);
                let (y, x) = self.snake.head();
                match direction {
                    KeyCode::Up => {
                        if y - 1 > 0 {
                            self.snake.take_step((y - 1, x));
                        } else {
                            return Ok(2);
                        }
                    }
                    KeyCode::Down => {
                        if y < self.height - 2 {
                            self.snake.take_step((y + 1, x));
                        } else {
                            return Ok(2);
                        }
                    }
                    KeyCode::Left => {
                        if x - 1 > 0 {
                            self.snake.take_step((y, x - 1));
                        } else {
                            return Ok(2);
                        }
                    }
                    KeyCode::Right => {
                        if x < self.width - 2 {
                            self.snake.take_step((y, x + 1));
                        } else {
                            return Ok(2);
                        }
                    }
                    _ => {}
                }
            }
            _ => {}
        }
        Ok(0)
    }

    fn clear_screen() -> std::io::Result<()> {
        execute!(stdout(), terminal::Clear(ClearType::All))?;
        execute!(stdout(), cursor::MoveTo(0, 0))
    }

    fn refresh_screen(&self) -> std::io::Result<()> {
        Self::clear_screen()?;
        self.render();
        execute!(stdout(), cursor::MoveTo(0, 0))
    }

    fn run(&mut self) -> std::io::Result<u32> {
        self.refresh_screen()?;
        self.process_keypress()
    }
}

fn main() -> std::io::Result<()> {
    let _clean_up = CleanUp;
    terminal::enable_raw_mode()?;

    println!("Hello, snake!");
    let mut game = Game::new(30, 40);
    while game.run()? == 0 {}
    if game.run()? == 2 {
        println!("Game, Over!");
    }
    Ok(())
}
