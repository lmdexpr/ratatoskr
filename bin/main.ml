open Async
open Core
open Disml
open Models

let check_command (message:Message.t) =
  let reply txt  = Message.reply message txt >>> ignore
  and cmd, _rest =
    match String.split ~on:' ' message.content with
    | hd::tl -> hd, tl
    | []     -> "", []
  in
    match cmd with
    | "!ping"   -> reply "Pong!"
    | "kawaii"  -> reply "せやろ"
    | "!encode" -> (try Commands.encode () |> reply with e -> begin reply "error!"; raise e end)
    | "!help"   -> reply Commands.help_txt
    | _         -> ()

let main () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level ~all:true (Some Logs.Debug);

  Client.message_create := check_command;
  let token =
    match Sys.getenv "RATATOSKR_DISCORD_TOKEN" with
    | Some t -> t
    | None -> failwith "No token in env"
  in
    Client.start token >>> ignore

let _ = Scheduler.go_main ~main ()

