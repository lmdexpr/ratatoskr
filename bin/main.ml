open Async
open Core
open Disml
open Models

(* Create a function to handle message_create. *)
let check_command (message:Message.t) =
  if String.is_prefix ~prefix:"!ping" message.content then
    Message.reply message "Pong!" >>> ignore

let main () =
  (* Register the event handler *)
  Client.message_create := check_command;
  (* Pull token from env var. It is not recommended to hardcode your token. *)
  let token = match Sys.getenv "DISCORD_TOKEN" with
  | Some t -> t
  | None -> failwith "No token in env"
  in
  (* Start client. *)
  Client.start token >>> ignore

let _ =
  (* Launch the Async scheduler. You must do this for anything to work. *)
  Scheduler.go_main ~main ()
