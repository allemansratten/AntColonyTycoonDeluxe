import random

from basic_game import Dude, Game, InteractiveGameCLI


def desync(dude: "Dude", game: "Game") -> "Dude":
    other_dude = None
    for d in game.dudes:
        if d != dude:
            other_dude = d
            break

    assert other_dude is not None

    if dude.kind != other_dude.kind:
        return dude
    else:
        if random.random() < 0.5:
            return dude.updated(new_kind=1 - dude.kind)
        else:
            return dude


def main():
    game = Game(size=2, dude_positions=[(0, 0), (0, 1)], dude_step_function=desync)

    cli = InteractiveGameCLI(game)
    cli.run()


if __name__ == "__main__":
    main()
