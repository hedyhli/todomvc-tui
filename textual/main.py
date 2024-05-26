from textual import on
from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.validation import Function
from textual.widgets import Button, Input, Label, ListItem, ListView

def validate_name(value: str):
    return len(value.strip()) > 0

class Todo:
    name: str
    complete: bool

    def __init__(self, name: str):
        self.name = name
        self.complete = False

    def listitem(self) -> ListItem:
        """Format as ListItem"""
        return ListItem(Label(self.text()))

    def text(self) -> str:
        """Format as label text"""
        s = "( )"
        if self.complete:
            s = "(X)"
        return f"{s} {self.name}"


class TodoList(ListView):
    todos: list[Todo]

    def key_space(self):
        self.action_select_cursor()

    def key_j(self):
        self.action_cursor_down()

    def key_k(self):
        self.action_cursor_up()

    def key_delete(self):
        # TODO
        self.todos.pop(self.index)
        self.pop(self.index)
        self.action_cursor_up()
        self.app.query_one("#itemsleft").update(format_itemsleft(self.todos))

    def key_e(self):
        item = self.todos[self.index]
        def result(value: str):
            if not value:
                return

            item.name = value
            self.children[self.index].children[0].update(item.text())

        self.app.push_screen(EditModal(item.name), result)


def format_itemsleft(todos: list[Todo]) -> str:
    n = len(list(filter(lambda t: not t.complete, todos)))
    return f"{n} item{'s' if n != 1 else ''} left"


class EditModal(ModalScreen):
    value: str

    def __init__(self, value: str):
        super().__init__()
        self.value = value

    def compose(self) -> ComposeResult:
        yield Vertical(
            Label("New name"),
            Input(
                placeholder="New name",
                value=self.value,
                id="edit",
                validators=[Function(validate_name)],
            ),
            Horizontal(
                Button("Cancel", id="cancel"),
                Button("Save", variant="success", id="save"),
            ),
            id="dialog",
        )

    @on(Input.Submitted)
    def save(self, event: Input.Submitted):
        if event.validation_result and event.validation_result.failures:
            with event.input.prevent(Input.Changed):
                event.input.clear()
            return
        self.dismiss(event.value)

    def on_button_pressed(self, event: Button.Pressed) -> None:
        self.dismiss(self.query_one("#edit").value if event.button.id == "save" else "")


class TodoMVC(App):
    todos: list[Todo] = []

    CSS = """
    Screen {
        align: center top;
    }

    EditModal {
        align: center middle;
    }

    #dialog {
        padding: 0 1;
        width: 60;
        height: 11;
        border: solid grey;
    }

    #dialog Input {
        margin: 1 0;
    }

    #dialog Horizontal Button {
        width: 50%;
    }

    TodoList, #newtodo, #itemsleft {
        margin: 0 20;
    }

    TodoList {
        border: solid white;
        max-height: 50%;
        max-width: 100;
    }

    #hero {
        content-align: center middle;
        width: 100%;
        margin-top: 5;
        margin-bottom: 3;
    }

    ListItem {
        padding: 1 3;
    }

    #itemsleft {
        content-align: right top;
        width: 100%;
    }

    #footer {
        dock: bottom;
        content-align: center middle;
        width: 100%;
    }
    """

    keys = {
        'tab': 'Switch focus',
        'up/down/j/k': 'Select in list',
        'enter/space': "Toggle complete",
        'e': 'Edit',
        'delete': 'Remove completed',
    }

    def compose(self) -> ComposeResult:
        yield Label("T O D O M V C", id="hero")
        yield Input(
            placeholder="What needs to be done?",
            id="newtodo",
            validators=[Function(validate_name)],
            validate_on=['submitted'],
        )
        todolist = TodoList(*(t.listitem() for t in self.todos))
        todolist.todos = self.todos
        yield todolist
        yield Label("", id="itemsleft")
        f = ", ".join(f"[bold]{k}[/bold]: [grey]{v}" for k, v in self.keys.items())
        yield Label(f, id="footer")

    @on(Input.Submitted)
    def make_todo(self, event: Input.Submitted):
        if event.validation_result and event.validation_result.failures:
            with event.input.prevent(Input.Changed):
                event.input.clear()
            return
        t = Todo(event.value)
        self.todos.append(t)
        self.query_one("#itemsleft").update(format_itemsleft(self.todos))
        self.query_one(TodoList).append(t.listitem())
        with event.input.prevent(Input.Changed):
            event.input.clear()

    @on(TodoList.Selected)
    def toggle(self, event: TodoList.Selected):
        t = self.todos[event.list_view.index]
        t.complete = not t.complete
        event.item.children[0].update(t.text())
        self.query_one("#itemsleft").update(format_itemsleft(self.todos))


if __name__ == "__main__":
    app = TodoMVC()
    app.run()
