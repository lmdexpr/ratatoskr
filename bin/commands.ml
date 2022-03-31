open Core

let help_txt =
  let title       = "I'm ratatoskr running up and down the yggdrasill !" 
  and help_text   = "!help : show this help."
  and ping_help   = "!ping : reply Pong!"
  and continue_morning_help = "ohayo! : if you greet to ratatoskr, then ratatoskr continue your greeting. e.g. when you say 'oh', ratatoskr continue 'ayo!'"
  and encode_help = "!encode : encode a ratatoskr/workspace/<name>.zip (included *.flac files) to a ratatoskr/output/<name>.mp3 file."
  in
    String.concat ~sep:"\n" [title; ping_help; continue_morning_help; encode_help; help_text]

let morning_greeting = "ohayo!"
let check_morning_greeting inp =
  let open Str in
  match split (quote inp |> regexp) morning_greeting with
  | [ t ] -> Some t
  | _     -> None

let encode () = 
  let check_extension ext file = Filename.check_suffix file ("." ^ ext) in

  let tmp_dir = Filename.concat Filename.temp_dir_name "ratatoskr" in
  let ratatoskr_dir =
    match Sys.getenv "RATATOSKR_PATH" with
    | Some path -> path
    | None      -> failwith "No ratatoskr path in env"
  in
  let ratatoskr_workspace = Filename.concat ratatoskr_dir "workspace" in

  begin
    print_endline tmp_dir;
    Unix.mkdir_p tmp_dir;
    Sys.readdir ratatoskr_workspace |> Array.to_list |> List.filter ~f:(check_extension "zip") |> List.map ~f:(Filename.concat ratatoskr_workspace) |> fun files ->
      match List.hd files with
      | None               -> "no zip file!"
      | Some zip_full_path ->
          let file_name = Filename.basename zip_full_path in
          let name      = Filename.chop_extension file_name in
          let tmp_dir   = Filename.concat tmp_dir name in
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
          let ffmpeg_cmd =
            if count > 1 then "ffmpeg " ^ inputs ^ " -filter_complex amix=inputs=" ^ (string_of_int count) ^ ":duration=longest -ab 32k -acodec libmp3lame -f mp3 " ^ name_mp3
            else "ffmpeg " ^ inputs ^ " -ab 32k -acodec libmp3lame -f mp3 " ^ name_mp3
          in
          let _ =
            print_endline ffmpeg_cmd;
            Sys.command ffmpeg_cmd |> ignore;
            let mv = String.concat ~sep:" " ["mv"; "-f"; name_mp3; ratatoskr_dir ^ "output/" ^ name ^ ".mp3"] in Sys.command mv |> ignore;
            Sys.command ("rm -rf " ^ zip_full_path) |> ignore;
            Sys.command ("rm -rf " ^ tmp_dir) |> ignore
          in
            "ok!\nprocessed: " ^ file_name ^ "\nif you want to make me work more, delete processed file and re-command !encode"
  end

