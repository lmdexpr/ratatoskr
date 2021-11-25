open Async
open Core
open Disml
open Models

let help message =
  let title       = "I'm ratatoskr running up and down the yggdrasill !" 
  and help_text   = "!help : show this help."
  and ping_help   = "!ping : replied Pong!"
  and encode_help = "!encode : encode ratatoskr/workspace/<name>.zip (included *.flac files) to a ratatoskr/output/<name>.mp3 file. And, delete all zip files." in
  let summary     = String.concat ~sep:"\n" [title; ping_help; encode_help; help_text]
  in Message.reply message summary >>> ignore

let encode encoder message =
  let _ = Sys.command encoder
  in Message.reply message "ok !" >>> ignore

let check_command encoder (message:Message.t) =
  let cmd, _rest =
    match String.split ~on:' ' message.content with
    | hd::tl -> hd, tl
    | [] -> "", []
  in match cmd with
    | "!ping"   -> Message.reply message "Pong!" >>> ignore
    | "kawaii"  -> Message.reply message "せやろ" >>> ignore
    | "!encode" -> encode encoder message
    | "!help"   -> help message
    | _         -> ()

let setup_logger () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level ~all:true (Some Logs.Debug)

let main () =
  setup_logger ();
  let encode_command =
    match Sys.getenv "RATATOSKR_ENCODER" with
    | Some ec -> ec
    | None    -> failwith "No encoder in env"
  in
    Client.message_create := check_command encode_command;
  let token =
    match Sys.getenv "RATATOSKR_DISCORD_TOKEN" with
    | Some t -> t
    | None -> failwith "No token in env"
  in
    Client.start token >>> ignore

let _ = Scheduler.go_main ~main ()
