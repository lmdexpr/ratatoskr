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
  in
    Message.reply message summary

let encode () = 
  let check_extension ext file = Filename.check_suffix file ("." ^ ext) in

  let tmp_dir = Filename.concat Filename.temp_dir_name "ratatoskr" in
  let ratatoskr_dir =
    match Sys.getenv "RATATOSKR_PATH" with
    | Some path -> path
    | None      -> failwith "No ratatoskr path in env"
  in
  let ratatoskr_workspace = Filename.concat ratatoskr_dir "workspace" in

  let inner zip_full_path =
    let name    = Filename.basename zip_full_path |> Filename.chop_extension in
    let tmp_dir = Filename.concat tmp_dir name in
    let _ = begin
      print_endline zip_full_path;
      print_endline tmp_dir;
      Unix.mkdir_p tmp_dir;
      Sys.chdir tmp_dir;
      Sys.command ("unzip -j " ^ zip_full_path ^ " \"*.flac\"")
    end in

    let flacs      = Sys.readdir tmp_dir |> Array.filter ~f:(check_extension "flac") in
    let count      = Array.length flacs in
    let inputs     = Array.map ~f:(fun flac -> "-i " ^ flac) flacs |> String.concat_array ~sep:" " in
    let name_mp3   = tmp_dir ^ "/" ^ name ^ ".mp3" in
    let ffmpeg_cmd = "ffmpeg " ^ inputs ^ " -filter_complex amix=inputs=" ^ (string_of_int count) ^ ":duration=longest -ab 32k -acodec libmp3lame -f mp3 " ^ name_mp3 in begin
      if count > 1 then begin
        print_endline ffmpeg_cmd;
        Sys.command ffmpeg_cmd |> ignore;
        let mv = String.concat ~sep:" " ["mv"; "-f"; name_mp3; ratatoskr_dir ^ "output/" ^ name ^ ".mp3"] in Sys.command mv |> ignore;
        Unix.remove zip_full_path
      end;
      Sys.command ("rm -rf " ^ tmp_dir) |> ignore
    end
  in begin
    print_endline tmp_dir;
    Unix.mkdir_p tmp_dir;
    Sys.readdir ratatoskr_workspace |> Array.to_list |> List.filter ~f:(check_extension "zip") |> List.map ~f:(Filename.concat ratatoskr_workspace) |> fun files ->
      let hd = List.hd files
      and tl = List.tl files in
      let _  = Option.value_map hd ~default:() ~f:inner in
      if Option.is_some hd then
        if Option.is_some tl then
          "ok! reply !encode if you want to make me work more"
        else
          "ok!"
      else
        "no zip file!"
  end

let check_command (message:Message.t) =
  let cmd, _rest =
    match String.split ~on:' ' message.content with
    | hd::tl -> hd, tl
    | []     -> "", []
  in
    match cmd with
    | "!ping"   -> Message.reply message "Pong!" >>> ignore
    | "kawaii"  -> Message.reply message "せやろ" >>> ignore
    | "!encode" -> encode () |> Message.reply message >>> ignore
    | "!help"   -> help message >>> ignore
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

