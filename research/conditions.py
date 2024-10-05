import random
from typing import Callable

from basic_game import Dude, Game

DudeCondition = Callable[[Dude, Game], bool]
DudeAction = Callable[[Dude], Dude]


def has_hat(dude: Dude, game: Game) -> bool:
    return dude.has_hat


def does_not_have_hat(dude: Dude, game: Game) -> bool:
    return not dude.has_hat


def is_next_to_hat(dude: Dude, game: Game) -> bool:
    for d in game.dudes:
        if d.has_hat and dude.is_neighbor(d):
            return True
    return False


def is_not_next_to_hat(dude: Dude, game: Game) -> bool:
    return not is_next_to_hat(dude, game)


def coin_flip(dude: Dude, game: Game) -> bool:
    return random.random() < 0.5


def make_step_function(
    branches: list[tuple[list[DudeCondition] | DudeCondition, DudeAction]],
):
    def step_function(dude: Dude, game: Game) -> Dude:
        for conditions, action in branches:
            if not isinstance(conditions, list):
                conditions = [conditions]

            all_conditions_met = True
            for condition in conditions:
                if not condition(dude, game):
                    all_conditions_met = False
                    break

            if all_conditions_met:
                return action(dude)

        return dude

    return step_function
