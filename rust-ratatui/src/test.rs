use super::*;

#[test]
fn todo() {
    let mut t = Todo::new("name".to_string());
    assert_eq!("name".to_string(), t.name);
    assert_eq!(false, t.complete);
    t.toggle();
    assert_eq!(true, t.complete);
    t.toggle();
    assert_eq!(false, t.complete);
}

#[test]
fn todos() {
    let mut ts = vec![Todo::new("1".to_string()), Todo::new("2".to_string())];
    assert_eq!(fmt_itemsleft(&ts), "2 items left");
    ts[0].toggle();
    assert_eq!(fmt_itemsleft(&ts), "1 item left");
    ts[1].toggle();
    assert_ne!(fmt_itemsleft(&ts), "1 item left");
    assert_ne!(fmt_itemsleft(&ts), "2 items left");
}

#[test]
fn inputs() {
    let mut inp = Inputter::new();
    assert_eq!("".to_string(), inp.input);
    inp.insert('a');
    inp.insert('b');
    inp.insert('c');
    assert_eq!("abc".to_string(), inp.input);
    assert_eq!(3, inp.cursor);
    inp.right();
    assert_eq!(3, inp.cursor);
    inp.left();
    inp.left();
    inp.left();
    assert_eq!(0, inp.cursor);
    inp.left();
    assert_eq!(0, inp.cursor);

    inp.cursor = 2;
    inp.delete_left();
    assert_eq!("ac".to_string(), inp.input);
    assert_eq!(1, inp.cursor);

    inp.cursor = 2;
    inp.insert('d');
    inp.cursor = 0;
    inp.delete_right();
    assert_eq!("cd".to_string(), inp.input);
    assert_eq!(0, inp.cursor);
}

#[test]
fn inputs_saving() {
    let mut inp = Inputter::new();
    inp.insert('a');
    inp.insert('b');
    inp.insert('c');
    inp.left();

    inp.save();
    inp.input = "edit name".to_string();
    inp.cursor = inp.input.chars().count();
    inp.restore();
    assert_eq!(2, inp.cursor);
    assert_eq!("abc".to_string(), inp.input);
}
