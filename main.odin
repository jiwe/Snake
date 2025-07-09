package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

vec2 :: rl.Vector2
rect :: rl.Rectangle

CELL_SIZE :: 30
CELL_COUNT :: 25
OFFSET :: 75

GREEN := rl.Color{173, 204, 96, 255}
DARK_GREEN := rl.Color{43, 51, 24, 255}

last_update_time: f64

Game :: struct {
	snake: Snake,
	food: Food,
	running: bool,
	score: int,
	eat_sound: rl.Sound,
	wall_sound: rl.Sound,
}

Snake :: struct {
	body: [dynamic]vec2,
	direction: vec2,
	add_segment: bool,
}

Food :: struct {
	position: vec2,
	texture: rl.Texture2D,
}

Direction :: enum {
	Left,
	Right,
	Forward,
}

event_triggered :: proc(interval: f64) -> bool {
	current_time := rl.GetTime()
	if current_time - last_update_time > interval {
		last_update_time = current_time
		return true
	}
	return false
}

snake_init ::proc() -> Snake {
	snake := Snake {
		body = make([dynamic]vec2, 0, 100),
		direction = vec2{1, 0},
		add_segment = false,
	}
	append(&snake.body, vec2{6, 9})
	append(&snake.body, vec2{5, 9})
	append(&snake.body, vec2{4, 9})
	return snake
}

snake_reset :: proc(snake: ^Snake) {
	clear(&snake.body)
	append(&snake.body, vec2{6, 9})
	append(&snake.body, vec2{5, 9})
	append(&snake.body, vec2{4, 9})
	snake.direction = vec2{1, 0}
}

snake_draw :: proc(snake: ^Snake) {
	for segment in snake.body {
		segment_rect := rect{
			OFFSET + segment.x * CELL_SIZE,
			OFFSET + segment.y * CELL_SIZE,
			CELL_SIZE,
			CELL_SIZE,
		}
		rl.DrawRectangleRounded(segment_rect, 0.5, 6, DARK_GREEN)
	}
}

snake_update :: proc(snake: ^Snake) {
	new_head := vec2{
		snake.body[0].x + snake.direction.x,
		snake.body[0].y + snake.direction.y,
	}

	inject_at(&snake.body, 0, new_head)
	if !snake.add_segment {
		pop(&snake.body)
	}
	snake.add_segment = false
}

element_in_slice :: proc(element: vec2, slice: []vec2) -> bool {
	for v in slice {
		if v.x == element.x && v.y == element.y {
			return true
		}
	}
	return false
}

generate_random_cell :: proc() -> vec2 {
	x := rand.int_max(CELL_COUNT)
	y := rand.int_max(CELL_COUNT)
	return vec2{f32(x), f32(y)}
}

generate_random_pos ::proc(snake_body: []vec2) -> vec2 {
	position := generate_random_cell()
	for element_in_slice(position, snake_body) {
		position = generate_random_cell()
	}
	return position
}

food_init ::proc(snake_body: []vec2) -> Food {
	image := rl.LoadImage("assets/food.png")
	texture := rl.LoadTextureFromImage(image)
	rl.UnloadImage(image)

	return Food {
		position = generate_random_pos(snake_body),
		texture = texture,
	}
}

food_draw :: proc(food: ^Food) {
	rl.DrawTexture(
		food.texture,
		i32(OFFSET + food.position.x * CELL_SIZE),
		i32(OFFSET + food.position.y * CELL_SIZE),
		rl.WHITE,
	)
}

game_init :: proc() -> Game {
	rl.InitAudioDevice()
	snake := snake_init()

	game := Game {
		snake = snake,
		food = food_init(snake.body[:]),
		running = true,
		score = 0,
		eat_sound = rl.LoadSound("assets/eat.mp3"),
		wall_sound = rl.LoadSound("assets/wall.mp3"),
	}

	return game
}

game_draw :: proc(game: ^Game) {
	food_draw(&game.food)
	snake_draw(&game.snake)
}

game_update :: proc(game: ^Game) {
	if game.running {
		snake_update(&game.snake)
		check_collection_with_food(game)
		check_collection_with_edges(game)
		check_collection_with_tail(game)
	}
}

game_over :: proc(game: ^Game) {
	snake_reset(&game.snake)
	game.food.position = generate_random_pos(game.snake.body[:])
	game.running = false
	game.score = 0
	rl.PlaySound(game.wall_sound)
}

check_collection_with_food :: proc(game: ^Game) {
	if game.snake.body[0] == game.food.position {
		game.food.position = generate_random_pos(game.snake.body[:])
		game.snake.add_segment = true
		game.score += 1
		rl.PlaySound(game.eat_sound)
	}
}

check_collection_with_edges:: proc(game: ^Game) {
	if game.snake.body[0].x == -1 || game.snake.body[0].x == CELL_COUNT||
		game.snake.body[0].y == -1 || game.snake.body[0].y== CELL_COUNT {
		game_over(game)
	}
}

check_collection_with_tail :: proc(game: ^Game) {
	if len(game.snake.body) > 1 {
		if element_in_slice(game.snake.body[0], game.snake.body[1:]) {
			game_over(game)
		}
	}
}

turn_left :: proc(g: ^Game) {
	switch g.snake.direction {
		case vec2{0, -1} :
			g.snake.direction = vec2{-1, 0}
		case vec2{0, 1} :
			g.snake.direction = vec2{1, 0}
		case vec2{-1, 0} :
			g.snake.direction = vec2{0, 1}
		case vec2{1, 0} :
			g.snake.direction = vec2{0, -1}
	}
}

turn_right :: proc(g: ^Game) {
	switch g.snake.direction {
		case vec2{0, -1} :
			g.snake.direction = vec2{1, 0}
		case vec2{0, 1} :
			g.snake.direction = vec2{-1, 0}
		case vec2{-1, 0} :
			g.snake.direction = vec2{0, -1}
		case vec2{1, 0} :
			g.snake.direction = vec2{0, 1}
	}
}

history_distance :f32 = 1000.0

state :: proc(g: ^Game, direction: Direction) -> int{
	reward : int

	try_x := g.snake.body[0].x
	try_y := g.snake.body[0].y
	
	switch g.snake.direction {
		case vec2{0, -1} :
			switch direction {
				case .Forward :
					try_y -= 1  
				case .Left :
					try_x -= 1  
				case .Right :
					try_x += 1  
			}
		case vec2{0, 1} :
			switch direction {
				case .Forward :
					try_y += 1  
				case .Left :
					try_x += 1  
				case .Right :
					try_x -= 1  
			}
		case vec2{-1, 0} :
			switch direction {
				case .Forward :
					try_x -= 1  
				case .Left :
					try_y += 1  
				case .Right :
					try_y -= 1  
			}
		case vec2{1, 0} :
			switch direction {
				case .Forward :
					try_x += 1  
				case .Left :
					try_y -= 1  
				case .Right :
					try_y += 1  
			}
	}

	if try_x < 0 || try_x > CELL_COUNT - 1 {
		reward -= 100
	}
	if try_y == -1 || try_y > CELL_COUNT - 1 {
		reward -= 100
	}
	if try_x == g.food.position.x && try_y == g.food.position.y {
		reward += 100
	}

	if math.abs(try_x - g.food.position.x) < math.abs(g.snake.body[0].x - g.food.position.x)  {
		reward += 5
	}
	if math.abs(try_y - g.food.position.y) < math.abs(g.snake.body[0].y - g.food.position.y)  {
		reward += 5
	}

	for v in g.snake.body[1:] {
		if try_x == v.x && try_y == v.y {
			reward -= 100
		}
	}
	
	return reward
}

vector2_distance :: proc(a: vec2, b: vec2) -> f32 {
	x := a.x - b.x
	y := a.y - b.y
	return x * x + y * y
}

ai :: proc(g: ^Game) {
	try_f := state(g, .Forward)
	try_l := state(g, .Left)
	try_r := state(g, .Right)

	fmt.println("try reward:", try_f, try_l, try_r)

	if try_f >= try_l && try_f >= try_r {
		// continue
	} else {
		if try_l > try_r {
			turn_left(g)
		} else {
			turn_right(g)
		}
	}
}

ai2 :: proc(g: ^Game) {
	try_f := state(g, .Forward)
	try_l := state(g, .Left)
	try_r := state(g, .Right)
	fmt.println("ai2 try reward:", try_f, try_l, try_r)

	if try_f >= 100 {
		return
	} else if try_l >= 100 {
		turn_left(g)
		return
	} else if try_r >= 100 {
		turn_right(g)
		return
	}

	if vector2_distance(g.snake.body[0], g.food.position) < vector2_distance(g.snake.body[1], g.food.position) && try_f >= 0{
		// continue
	} else {
		random_index := rand.int_max(2)
		if random_index == 0 && try_l >= 0 {
			turn_left(g)
		}
		if random_index == 1 && try_r >= 0 {
			turn_right(g)
		}
	}
}


main :: proc() {
	rl.InitWindow(
		2 * OFFSET + CELL_SIZE * CELL_COUNT,
		2 * OFFSET + CELL_SIZE * CELL_COUNT,
		"Intelligence"
	)
	rl.SetTargetFPS(60)

	g := game_init()
	allow_move := false
	
	for !rl.WindowShouldClose() {
		if event_triggered(0.2) {
			allow_move = true
			game_update(&g)
		}

		if rl.IsKeyPressed(.UP) && g.snake.direction.y != 1 && allow_move {
			g.snake.direction = vec2{0, -1}
			g.running = true
			allow_move = false
		}
		if rl.IsKeyPressed(.DOWN) && g.snake.direction.y != -1 && allow_move {
			g.snake.direction = vec2{0, 1}
			g.running = true
			allow_move = false
		}
		if rl.IsKeyPressed(.LEFT) && g.snake.direction.x != 1 && allow_move {
			g.snake.direction = vec2{-1, 0}
			g.running = true
			allow_move = false
		}
		if rl.IsKeyPressed(.RIGHT) && g.snake.direction.x != -1 && allow_move {
			g.snake.direction = vec2{1, 0}
			g.running = true
			allow_move = false
		}

		if allow_move {
			ai2(&g)
			g.running = true
			allow_move = false
		}
		
		rl.BeginDrawing()
		rl.ClearBackground(GREEN)

		border_rect := rect {
			f32(OFFSET -5),
			f32(OFFSET -5),
			f32(CELL_SIZE * CELL_COUNT + 10),
			f32(CELL_SIZE * CELL_COUNT + 10),
		} 
		rl.DrawRectangleLinesEx(border_rect, 5, DARK_GREEN)

		rl.DrawText("Snake", OFFSET - 5, 20, 40, DARK_GREEN)
		rl.DrawText(
			fmt.ctprintf("%d", g.score),
			OFFSET -5,
			OFFSET + CELL_SIZE * CELL_COUNT + 10,
			40,
			DARK_GREEN,
		)

		game_draw(&g)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}

