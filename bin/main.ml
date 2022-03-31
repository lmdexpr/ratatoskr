open Async
open Core
open Disml
open Models

let check_command bot_user_id (message:Message.t) =
  let reply txt  = Message.reply message txt >>> ignore
  and cmd, _rest =
    match String.split ~on:' ' message.content with
    | hd::tl -> hd, tl
    | []     -> "", []
  in
  let `User_id writer_id = message.author.id in
  if writer_id = bot_user_id then ()
  else
    match cmd with
    | "!ping"   -> reply "Pong!"
    | "kawaii"  -> reply "せやろ"
    | "!encode" -> (try Commands.encode () |> reply with e -> begin reply "error!"; raise e end)
    | "!help"   -> reply Commands.help_txt
    | other     -> Option.iter ~f:reply (Commands.check_morning_greeting other)

let main () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level ~all:true (Some Logs.Debug);

  let bot_user_id =
    match Sys.getenv "RATATOSKR_USER_ID" with
    | Some t -> int_of_string t
    | None -> 0
  in
  Client.message_create := check_command bot_user_id;
  let token =
    match Sys.getenv "RATATOSKR_DISCORD_TOKEN" with
    | Some t -> t
    | None -> failwith "No token in env"
  in
    Client.start token >>> ignore

let _ = Scheduler.go_main ~main ()

