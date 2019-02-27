(** lintshell, a user-extensible lint for shell. *)

open Lintshell

(*-------------------------*)
(* Command line processing *)
(*-------------------------*)

let arguments = ref []
let user_paths = ref []
let push l a = l := a :: !l

let options = Arg.(align [
    "-I", String (push user_paths), " Specify search path for plugins"
])

let usage_msg = "\
Usage: lintshell check [options] file...
   or: lintshell list
"

let show_usage () =
  output_string stdout usage_msg;
  exit 1

let input_files = ref []

(*-------------------*)
(* Plugin management *)
(*-------------------*)

open Analyzer

let search_paths () = [
    "lib/lintshell/plugins";
(*    Filename.concat (Sys.getenv "$HOME") ".lintshell" *)
] @ !user_paths

let load_available_analyzers () =
  let rec aux dirname =
    Sys.readdir dirname
    |> Array.iter
         (fun file ->
           let file = Filename.concat dirname file in
           if Filename.check_suffix file ".cma" then
             (
               let file = Dynlink.adapt_filename file in
               try
                 Dynlink.loadfile file
               with
                 Dynlink.Error e ->
                 Printf.eprintf "Warning: `%s' did not load correctly (%s).\n"
                   file (Dynlink.error_message e)
             )
           else if Sys.is_directory file then
             aux file)
  in
  List.iter aux (search_paths ())

let list () = Analyzer.(
    List.iter show_documentation (analyzers ())
)

(*------------*)
(* Processing *)
(*------------*)

let check () =
  let run_analyzer cst (module Analyzer : Analyzer.S) =
    Analyzer.analyzer cst
  in
  let report = Alarm.report in
  let process filename =
    let cst = Morbig.parse_file filename in
    Analyzer.analyzers ()
    |> List.map (run_analyzer cst)
    |> List.flatten
    |> List.iter report
  in
  List.iter process !input_files

(*--------*)
(* Driver *)
(*--------*)

let () =
  Arg.parse options (push arguments) usage_msg;
  load_available_analyzers ();
  match List.rev !arguments with
  | "check" :: files ->
    input_files := files;
    check ()
  | ["list"] ->
    list ()
  | _ ->
    show_usage ()
