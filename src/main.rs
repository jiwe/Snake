enum Direction {
    UP,
    Down,
    LEFT,
    RIGHT,
}

struct Snake {
    body: Vec<(usize, usize)>,
    direction: Direction,
}

impl Snake {
    fn new(body: Vec<(usize, usize)>, direction: Direction) -> Snake {
        Snake { body, direction }
    }

    fn take_step(&mut self, position: (usize, usize)) {
        self.body.remove(0);
        self.body.push(position);
    }

    fn set_direction(&mut self, direction: Direction) {
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
            snake: Snake::new(vec![(2, 2), (2, 3), (3, 3), (4, 3)], Direction::UP),
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
}

fn main() {
    println!("Hello, snake!");
    let game = Game::new(20, 30);
    game.render();
    print!("\r\n");
}
