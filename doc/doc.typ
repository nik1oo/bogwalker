#import "@preview/min-manual:0.2.1": manual
#show: manual.with(
	title: "Bogwalker",
	description: "A minesweeper-esque game about avoiding monsters in a swamp.",
	package: "bogwalker:1.0.0",
	authors: "Nikola Stefanov                      blatnoneshto@gmail.com",
	license: "MIT",
	logo: image("logo.png"))
#let proc(x, y) = rect(stroke: black, inset: 0.8em, outset: 0pt, width: 100%, [
	#text(size: 14pt, raw(x))\

	#y])

= Procedures

#proc("seed_board::proc(board:^Board)")[Assign a random seed to every cell on the board. Seeds are used to pick a variant, for visual elements that have variants.]

#proc("clear_board::proc(board:^Board)")[Remove all entities from the board and make every tile invisible.]
