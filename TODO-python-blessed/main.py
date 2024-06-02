import blessed


def run(term: blessed.Terminal):
    print(term.home + term.clear + term.move_y(1))
    print(term.black_on_darkkhaki(term.center("press any key to continue.")))

    term.hidden_cursor()
    print(term.move_down(1))

    while True:
        inp = term.inkey()
        print(f"{inp.name = } {inp.code = } {str(inp) = } {inp.is_sequence = }")

if __name__ == "__main__":
    term = blessed.Terminal()
    try:
        with term.fullscreen(), term.cbreak():
            run(term)
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(e)
        exit(1)
