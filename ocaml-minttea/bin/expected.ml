open Minttea

type model = { quitting : bool }

let init _ = Command.Enter_alt_screen
let initial_model = { quitting = false }

let update event model =
  match event with
  | Event.KeyDown (Key "q" | Escape) ->
      ({ quitting = true }, Command.Quit)
  | _ -> (model, Command.Noop)

let view model =
  if model.quitting then ""
  else
    "in alt screen"

let () = Minttea.app ~init ~update ~view () |> Minttea.start ~initial_model
