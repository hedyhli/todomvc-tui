module Widgets = Nottui_widgets

let vcount = Lwd.var 0

open Lwd_infix
let ui_header = Widgets.string "T O D O M V C"
let ui =
    let$ _ = Lwd.get vcount in
    ui_header;;

Nottui.Ui_loop.run ui
