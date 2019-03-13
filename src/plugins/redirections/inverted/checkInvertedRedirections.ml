open Lintshell
open Morbig open CST

(* The goal of this checker is to see if there are so-called
   "inverted" redirections. Inverted redirections happen when, in a
   redirection list, one file descriptor ends up writing into what an
   other descriptor used to write into, while the latter is writing
   into something else.

   Example: 2>&1 >/dev/null

   In this example, when evaluating the whole redirection list, the
   file descriptor 1 ends up writing into /dev/null while the
   descriptor 2 ends up writing into what 1 used to point to.

   This is usually not what is meant. In the given example, one would
   expect to redirect both 1 and 2 to /dev/null, which is achieve
   with: >/dev/null 2>&1 *)

(* ==================== [ Checker on redirection lists ] ==================== *)

(* The way this checker works is by evaluating statically what a
   redirection list will do. To do so, we try to track what the
   redirections modify on an array of file descriptors. For each
   descriptor, we distinguish three cases: *)

type descriptor =
  | Initial of int  (* the descriptor writes to what the given
                       descriptor was writing to at the begining *)
  | Other           (* the descriptor points towards something that
                       does not matter *)
  | DontKnow        (* we cannot be sure whether wahat the descriptor
                       is writing to matters or not in this evaluation *)

type descriptors = descriptor array

let number_of_descriptors = 10

(* Initially, we know that each descriptor writes into what it was
   writing to initially. (If the sentence looks trivial, it's because
   it is) *)

let initial_descriptors () =
  Array.init number_of_descriptors (fun i -> Initial i)

(* In some situations, we will have to say that we don't know anything
   anymore on all the descriptors. This is what the [dontknow]
   function is for. *)

let dontknow descriptors =
  for i = 0 to Array.length descriptors - 1 do
    descriptors.(i) <- DontKnow
  done

(* [apply_io_number descriptors target default io_number_option] tries
   to detect which file descriptor is described by the
   [io_number_option] (or uses [default] if the option is [None]) and
   changes what this descriptor is writing into into [target]. *)

let apply_io_number descriptors target default = function
  | None ->
     descriptors.(default) <- target
  | Some (IONumber s) ->
     try descriptors.(int_of_string s) <- target
     with Failure _ -> dontknow descriptors

(* [apply_io_file descriptors io_number io_file] interprets what
   [io_file] changes for [io_number]. *)

let apply_io_file descriptors io_number = function
  | IoFile_Less_FileName _
  | IoFile_LessGreat_FileName _ ->
     apply_io_number descriptors Other 0 io_number
  | IoFile_Great_FileName _
  | IoFile_DGreat_FileName _
  | IoFile_Clobber_FileName _ ->
     apply_io_number descriptors Other 1 io_number
  | IoFile_LessAnd_FileName {value=Filename_Word {value=word;_};_} ->
     (try
        apply_io_number descriptors
          descriptors.(int_of_string (CSTHelpers.unWord word))
          0 io_number
      with Failure _ ->
        apply_io_number descriptors
          DontKnow
          0 io_number)
  | IoFile_GreatAnd_FileName {value=Filename_Word {value=word;_};_} ->
     (try
        apply_io_number descriptors
          descriptors.(int_of_string (CSTHelpers.unWord word))
          1 io_number
      with Failure _ ->
        apply_io_number descriptors
          DontKnow
          1 io_number)

let apply_io_here _descriptors _io_number _ = ()

(* [apply_io_redirect_list] applies all the redirections one after the
   other. *)

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

(* [find_inverted_descriptors] checks on a set of descriptors if there
   is an inversion. For the example 2>&1 >/dev/null, there would be
   one as [1] would write to [Other] and [2] would write to [Initial
   1]. *)

let find_inverted_descriptors descriptors =
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
  match find_inverted_descriptors descriptors with
  | None -> []
  | Some (i, j) ->
     [Alarm.make
        ~position:(List.hd io_redirect_list).position
        (Printf.sprintf
           "The file descriptor %d points to what %d used to point to; \
            but %d points to something else. \
            You probably want to change the order of your redirections." i j j)]

(* ========================= [ The checker itself ] ========================= *)

module Checker : Analyzer.S = struct

  let name = "redirections/inverted"

  let author = "Nicolas Jeannerod <nicolas.jeannerod@irif.fr>"

  let short_description =
    "Looks for inverted redirections like 2>&1 >/dev/null"

  let documentation =
    "Looks for inverted redirections like 2>&1 >/dev/null"

  let analyzer = Analyzer.check_program (fun program ->
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
    visitor#visit_program () program)
end

let register = Analyzer.register_analyzer (module Checker)
