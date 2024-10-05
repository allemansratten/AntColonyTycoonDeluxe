import copy
import curses
import sys
from io import StringIO
from typing import Callable

DudeStepFunction = Callable[["Dude", "Game"], "Dude"]


def do_nothing(dude: "Dude", game: "Game") -> "Dude":
    return dude


def move_right(dude: "Dude", game: "Game") -> "Dude":
    return Dude((dude.position[0], dude.position[1] + 1), dude.step_function)


class Dude:
    def __init__(
        self, position: tuple[int, int], step_function: DudeStepFunction = do_nothing
    ) -> None:
        self.kind = 0
        self.position = position
        self.step_function = step_function

    def step(self, game: "Game") -> "Dude":
        dude = self.step_function(self, game)
        dude.to_bounds(game.size)
        return dude

    def to_bounds(self, size: int) -> None:
        self.position = (
            max(0, min(size - 1, self.position[0])),
            max(0, min(size - 1, self.position[1])),
        )


class Game:
    def __init__(self) -> None:
        self.size = 5
        self.board = [[0] * self.size for _ in range(self.size)]
        self.dudes: list[Dude] = []

    def step(self) -> None:
        new_dudes = []
        for dude in self.dudes:
            new_dudes.append(dude.step(self))

        self.dudes = new_dudes

    def __str__(self) -> str:
        to_print = []

        for i, row in enumerate(self.board):
            to_print.append([])
            for j, cell in enumerate(row):
                cur = str(cell)

                for dude in self.dudes:
                    if dude.position == (i, j):
                        cur += "ABCDE"[dude.kind]

                to_print[-1].append(cur)

        res = ""

        for row in to_print:
            # 4 chars per row
            res += (
                "|" + "|".join(f"{str(item):<{5}}" for i, item in enumerate(row)) + "|"
            )
            res += "\n"

        res += "\n"
        return res


class InteractiveGameCLI:
    def __init__(self, game):
        self.game = game
        self.states = [str(game)]
        self.current_step = 0

    def run(self):
        curses.wrapper(self._main)

    def _main(self, stdscr):
        curses.curs_set(0)
        stdscr.clear()

        while True:
            stdscr.clear()
            self._display_game(stdscr)
            stdscr.refresh()

            key = stdscr.getch()
            if key == ord("q"):
                break
            elif key == curses.KEY_LEFT:
                self._move_left()
            elif key == curses.KEY_RIGHT:
                self._move_right()

    def _display_game(self, stdscr):
        game_output = self.states[self.current_step]
        stdscr.addstr(
            0,
            0,
            f"Step: {self.current_step} | ← Previous | Next → | q: Quit",
        )
        for i, line in enumerate(game_output.split("\n")):
            stdscr.addstr(i + 2, 0, line)

    def _move_left(self):
        if self.current_step > 0:
            self.current_step -= 1

    def _move_right(self):
        if self.current_step < len(self.states) - 1:
            self.current_step += 1
        else:
            self.game.step()
            self.states.append(str(self.game))
            self.current_step += 1


def main():
    game = Game()
    game.dudes.append(Dude((2, 3)))
    game.dudes.append(Dude((1, 1), step_function=move_right))

    cli = InteractiveGameCLI(game)
    cli.run()


if __name__ == "__main__":
    main()
