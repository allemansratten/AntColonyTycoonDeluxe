import random

from basic_game import Dude, Game, InteractiveGameCLI
from conditions import (
    coin_flip,
    does_not_have_hat,
    has_hat,
    is_next_to_hat,
    is_not_next_to_hat,
    make_step_function,
)

desync = make_step_function(
    [
        (
            [is_next_to_hat, has_hat, coin_flip],
            lambda dude: dude.model_copy(update={"has_hat": False}),
        ),
        (
            [is_not_next_to_hat, does_not_have_hat, coin_flip],
            lambda dude: dude.model_copy(update={"has_hat": True}),
        ),
    ]
)


def main():
    game = Game(size=2, dude_positions=[(0, 0), (0, 1)], dude_step_function=desync)

    cli = InteractiveGameCLI(game)
    cli.run()


if __name__ == "__main__":
    main()
