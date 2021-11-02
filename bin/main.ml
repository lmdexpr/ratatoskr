pen Async
open Core
open Disml
open Models

let help message =
  let help_text   = "!help : show this help."
  and ping_help   = "!ping : replied Pong!"
  and encode_help = "!encode : encode ratatoskr/workspace/<name>.zip (included *.flac files) to a ratatoskr/output/<name>.mp3 file. And, delete all zip files." in
  let summary     = String.concat ~sep:"\n" [ping_help; encode_help; help_text]
  in Message.reply message summary >>> ignore

let encode _message _args = ()

let check_command drive_path (message:Message.t) =
  let cmd, rest =
    match String.split ~on:' ' message.content with
    | hd::tl -> hd, tl
    | [] -> "", []
  in match cmd with
    | "!ping"   -> Message.reply message "Pong!" >>> ignore
    | "!encode" -> encode drive_path message rest
    | "!help"   -> help message
    | _         -> ()

let setup_logger () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level ~all:true (Some Logs.Debug)

let main () =
  setup_logger ();
  let drive_path =
    match Sys.getenv "DRIVE_PATH" with
    | Some path -> path
    | None-> failwith "No drive path in env"
  in
    Client.message_create := check_command drive_path;
  let token =
    match Sys.getenv "DISCORD_TOKEN" with
    | Some t -> t
    | None -> failwith "No token in env"
  in
    Client.start token >>> ignore

let _ = Scheduler.go_main ~main ()
