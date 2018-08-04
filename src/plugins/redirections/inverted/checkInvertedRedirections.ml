open Lintshell
open Libmorbig open CST

(* ==================== [ Checker on redirection lists ] ==================== *)

(* What we know on a descriptor *)
type descriptor =
  | Initial of int  (* what was at the begining for the given int *)
  | Other           (* pointing towards something *)
  | DontKnow        (* all info has been lost *)

type descriptors = descriptor array

let number_of_descriptors = 10

(* At first, we know that each descriptor points towards what it
   points to (yay) *)
let initial_descriptors () =
  Array.init number_of_descriptors (fun i -> Initial i)

let dontknow descriptors =
  for i = 0 to Array.length descriptors - 1 do
    descriptors.(i) <- DontKnow
  done

let apply_io_number descriptors default descriptor = function
  | None ->
     descriptors.(default) <- descriptor
  | Some (IONumber s) ->
     try descriptors.(int_of_string s) <- descriptor
     with Failure _ -> dontknow descriptors

let apply_io_file descriptors io_number = function
  | IoFile_Less_FileName _
  | IoFile_LessGreat_FileName _ ->
     apply_io_number descriptors 0 Other io_number
  | IoFile_Great_FileName _
  | IoFile_DGreat_FileName _
  | IoFile_Clobber_FileName _ ->
     apply_io_number descriptors 1 Other io_number
  | IoFile_LessAnd_FileName {value=Filename_Word {value=word;_};_} ->
     (try
        apply_io_number descriptors 0
          descriptors.(int_of_string (CSTHelpers.unWord word))
          io_number
      with Failure _ ->
        apply_io_number descriptors 0
          DontKnow
          io_number)
  | IoFile_GreatAnd_FileName {value=Filename_Word {value=word;_};_} ->
     (try
        apply_io_number descriptors 1
          descriptors.(int_of_string (CSTHelpers.unWord word))
          io_number
      with Failure _ ->
        apply_io_number descriptors 1
          DontKnow
          io_number)

let apply_io_here _descriptors _io_number _ = ()

let rec apply_io_redirect_list descriptors = function
  | [] -> ()
  | {value=io_redirect;_} :: others ->
     (
       match io_redirect with
       | IoRedirect_IoFile {value=io_file;_} ->
          apply_io_file descriptors None io_file
       | IoRedirect_IoNumber_IoFile (io_number, {value=io_file;_}) ->
          apply_io_file descriptors (Some io_number) io_file
       | IoRedirect_IoHere {value=io_here;_} ->
          apply_io_here descriptors None io_here
       | IoRedirect_IoNumber_IoHere (io_number, {value=io_here;_}) ->
          apply_io_here descriptors (Some io_number) io_here
     );
     apply_io_redirect_list descriptors others

let debug_print_descriptors descriptors =
  Array.iter
    (function
     | Initial i -> print_char ' '; print_int i
     | Other -> print_string " ."
     | DontKnow -> print_string " ?")
    descriptors;
  print_newline ()

let have_descriptors_crossed descriptors =
  let result = ref None in
  for i = 0 to Array.length descriptors -1 do
    match descriptors.(i) with
    | Initial j when j <> i ->
       (
         match descriptors.(j) with
         | Initial k when k = j -> ()
         | _ ->
            (* i points to what j used to point to; but j points to
               something else => this is what we wanted to detect *)
            result := Some (i, j)
       )
    | _ -> ()
  done;
  !result

let check_io_redirect_list io_redirect_list =
  let descriptors = initial_descriptors () in
  apply_io_redirect_list descriptors io_redirect_list;
  match have_descriptors_crossed descriptors with
  | None -> []
  | Some (i, j) ->
     [Alarm.make
        ~position:(List.hd io_redirect_list).position
        (Printf.sprintf "The file descriptor %d points to what %d used to point to; but %d points to something else. You probably want to change the order of your redirections." i j j)]

(* ========================= [ The checker itself ] ========================= *)

module Checker : Analyzer.S = struct
  let name = "redirections/inverted"
  let documentation = "Looks for inverted redirections like 2>&1 >/dev/null"

  let analyzer (csts: complete_command_list) =
    let visitor = object (self)
      inherit [_] reduce as super

      method zero = []
      method plus = (@)

      method! visit_command () command =
        (
          match command with
          | Command_CompoundCommand_RedirectList (_, redirect_list') ->
             (
               CSTHelpers.io_redirect_list_of_redirect_list redirect_list'.value
               |> check_io_redirect_list
             )
          | _ -> self#zero
        )
        |> self#plus (super#visit_command () command)

      method! visit_function_body () function_body =
        (
          match function_body with
          | FunctionBody_CompoundCommand_RedirectList (_, redirect_list') ->
             (
               CSTHelpers.io_redirect_list_of_redirect_list redirect_list'.value
               |> check_io_redirect_list
             )
          | _ -> self#zero
        )
        |> self#plus (super#visit_function_body () function_body)

      method! visit_simple_command () simple_command =
        CSTHelpers.io_redirect_list_of_simple_command simple_command
        |> check_io_redirect_list
        |> self#plus (super#visit_simple_command () simple_command)
      end
    in
    csts
    |> List.map (fun cst -> visitor#visit_complete_command () cst.value)
    |> List.flatten
end

let register = Analyzer.register_analyzer (module Checker)
