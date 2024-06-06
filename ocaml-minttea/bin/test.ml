open Minttea

type model = { quitting : bool; in_alt : bool }

let ref = Riot.Ref.make ()
let init _ = Command.Set_timer (ref, 0.1)
let initial_model = { quitting = false; in_alt = false }

let update event model =
  match event with
  | Event.KeyDown (Key "q" | Escape) ->
      ({ model with quitting = true }, Command.Quit)
  (* Entering alt screen after initialization fixes the issue. *)
  | Event.Timer _ref -> ({model with in_alt = true}, Command.Enter_alt_screen)
  | _ -> (model, Command.Noop)

let view model =
  if not model.in_alt then " "  (* empty string does not work *)
  else if model.quitting then ""
  else
    "in alt screen"

let () = Minttea.app ~init ~update ~view () |> Minttea.start ~initial_model
