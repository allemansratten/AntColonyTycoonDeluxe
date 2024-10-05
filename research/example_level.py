from basic_game import Dude, Game, InteractiveGameCLI, move_right


def move_down(dude: "Dude", game: "Game") -> "Dude":
    return Dude((dude.position[0] + 1, dude.position[1]), dude.step_function)


def main():
    game = Game()
    game.dudes.append(Dude((2, 3), step_function=move_down))
    game.dudes.append(Dude((1, 1), step_function=move_right))

    cli = InteractiveGameCLI(game)
    cli.run()


if __name__ == "__main__":
    main()
