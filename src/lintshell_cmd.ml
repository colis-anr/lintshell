(** lintshell, a user-extensible lint for shell. *)

(*-------------------------*)
(* Command line processing *)
(*-------------------------*)

let arguments = ref []
let user_paths = ref []
let push l a = l := a :: !l

let options = Arg.(align [
    "-I", String (push user_paths),
    " Specify search path for plugins"
])


let usage_msg = "\
Usage: lintshell check [options] file...
   or: lintshell list
   or: lintshell show analyzer
"

let show_usage () =
  output_string stdout usage_msg;
  exit 1

let input_files = ref []

(*-------------------*)
(* Plugin management *)
(*-------------------*)

open Lintshell.Analyzer

let is_lintshell_plugin s =
  Str.(string_match (regexp "^lintshell.plugins..*") s 0)

let search_paths () =
  Findlib.init ();
  Fl_package_base.load_base ();
  Fl_package_base.list_packages ()
  |> List.filter is_lintshell_plugin
  |> List.map Findlib.package_directory

let load_available_analyzers () =
  let rec traverse dirname dir_handle = Unix.(
    try
      let entry = Unix.readdir dir_handle in
      (if Filename.check_suffix entry ".cma" then
        let module_filename = Dynlink.adapt_filename entry in
        (try
           Dynlink.loadfile (Filename.concat dirname module_filename)
         with Dynlink.Error e ->
           Printf.eprintf "Warning: `%s' did not load correctly (%s).\n"
             module_filename
             (Dynlink.error_message e)
        ));
        traverse dirname dir_handle
    with End_of_file -> closedir dir_handle
  )
  in
  List.iter
    (fun dirname -> try
        traverse dirname (Unix.opendir dirname)
      with Unix.Unix_error(Unix.ENOENT, _, _) ->
        () (* Silently ignore non existing standard directories. *)
    )
    (search_paths ())

let list () = Lintshell.Analyzer.(
    List.iter show_short_description (analyzers ())
)

let show what = Lintshell.Analyzer.(
    try
      show_details (List.find (fun (module A : S) ->
        A.name = what
      ) (analyzers ()))
    with Not_found ->
      Printf.eprintf "Analyzer `%s' not found.\n" what;
      exit 1
  )

(*------------*)
(* Processing *)
(*------------*)

let check () =
  let analyzers =
    analyzers ()
  in
  let run_analyzer ast (module Analyzer : Lintshell.Analyzer.S) =
    Analyzer.(interpret analyzer ast)
  in
  let process filename =
    let ast = Morbig.parse_file filename in
    List.(flatten (map (run_analyzer ast) analyzers)) |>
    List.sort Alarm.compare |>
    List.iter Alarm.show
  in
  List.iter process !input_files

(*--------*)
(* Driver *)
(*--------*)

let process_command_line_arguments =
  Arg.parse options (push arguments) usage_msg;
  load_available_analyzers ();
  match List.rev !arguments with
  | "check" :: files ->
    input_files := files;
    check ()
  | ["list"] ->
    list ()
  | "show" :: what :: [] ->
    show what
  | arguments ->
    Printf.eprintf "Invalid arguments `%s'.\n" (String.concat " " arguments);
    show_usage ()
