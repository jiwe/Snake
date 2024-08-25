struct Snake;

struct Apple;

struct Game {
    height: usize,
    width: usize,
}

impl Game {
    fn initialize(height: usize, width: usize) -> Game {
        Game { height, width }
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
                } else if *element == 0 {
                    print!(" ");
                }
            }
        }
    }
}

fn main() {
    println!("Hello, snake!");
    let game = Game::initialize(30, 80);
    game.render();
    print!("\r\n");
}
