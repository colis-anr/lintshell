open Morbig
open CST
open ExtStd

module Alarm = Alarm

type alarm = Alarm.t

type command_prefix_item = [
  | `Assignment  of assignment_word'
  | `Redirection of io_redirect'
]

type command_suffix_item = [
  | `Word        of word'
  | `Redirection of io_redirect'
]

type command_program = [
  | `NoProgram
  | `Word of cmd_word'
  | `Name of cmd_name'
]

type command = {
  command_prefix  : command_prefix_item list;
  command_program : command_program;
  command_suffix  : command_suffix_item list;
}

let rec command_prefix_of_cmd_prefix = function
  | CmdPrefix_IoRedirect redirect ->
    [ `Redirection redirect ]
  | CmdPrefix_CmdPrefix_IoRedirect (prefix, redirect) ->
    command_prefix_of_cmd_prefix prefix.value @ [ `Redirection redirect ]
  | CmdPrefix_AssignmentWord assignment ->
    [ `Assignment assignment ]
  | CmdPrefix_CmdPrefix_AssignmentWord (prefix, assignment) ->
    command_prefix_of_cmd_prefix prefix.value @ [ `Assignment assignment ]

let rec command_suffix_of_cmd_suffix = function
  | CmdSuffix_IoRedirect redirect ->
    [ `Redirection redirect ]
  | CmdSuffix_CmdSuffix_IoRedirect (suffix, redirect) ->
    command_suffix_of_cmd_suffix suffix.value @ [ `Redirection redirect ]
  | CmdSuffix_Word word ->
    [ `Word word ]
  | CmdSuffix_CmdSuffix_Word (suffix, word) ->
    command_suffix_of_cmd_suffix suffix.value @ [ `Word word ]

let command_of_simple_command = function
  | SimpleCommand_CmdPrefix_CmdWord_CmdSuffix (prefix, program, suffix) ->
    { command_prefix = command_prefix_of_cmd_prefix prefix.value;
      command_program = `Word program;
      command_suffix = command_suffix_of_cmd_suffix suffix.value
    }
  | SimpleCommand_CmdPrefix_CmdWord (prefix, program) ->
    { command_prefix = command_prefix_of_cmd_prefix prefix.value;
      command_program = `Word program;
      command_suffix = []
    }
  | SimpleCommand_CmdPrefix (prefix) ->
    { command_prefix = command_prefix_of_cmd_prefix prefix.value;
      command_program = `NoProgram;
      command_suffix = []
    }
  | SimpleCommand_CmdName_CmdSuffix (program, suffix) ->
    {
      command_prefix = [];
      command_program = `Name program;
      command_suffix = command_suffix_of_cmd_suffix suffix.value
    }
  | SimpleCommand_CmdName program ->
    {
      command_prefix = [];
      command_program = `Name program;
      command_suffix = []
    }

type analyzer =
  | CheckCommand of (position -> command -> alarm list)
  | CheckProgram of (program -> alarm list)
  | Sequence  of analyzer list

let check_program f = CheckProgram f

let check_command f = CheckCommand f

let sequence l = Sequence l

module type S = sig

  val name : string
  val author : string
  val short_description : string
  val documentation : string
  val analyzer : analyzer

end

let _analyzers : (module S) list ref = ref []
let analyzers () = !_analyzers

let register_analyzer (module Analyzer : S) =
  _analyzers := (module Analyzer) :: !_analyzers

let show_short_description (module Analyzer : S) =
  Printf.printf "%-30s %s\n"
    Analyzer.name
    Analyzer.short_description

let show_details (module Analyzer : S) =
  Printf.printf "Name:    %s\nAuthor:  %s\nSummary: %s\nDescription:%s"
    Analyzer.name
    Analyzer.author
    Analyzer.short_description
    (indent 2 Analyzer.documentation)

(** Analyzers interpretation. *)
let selector select a =
  let rec aux accu = function
    | Sequence analysers -> List.fold_left aux accu analysers
    | x -> match select x with None -> accu | Some x -> x :: accu
  in
  aux [] a

let interpret : analyzer -> (program -> alarm list) =
  fun analyzer ->
    let alarms = ref [] in
    let push a = alarms := a @ !alarms in

    let program_filters =
      selector (function CheckProgram f -> Some f | _ -> None) analyzer
    in
    let command_filters =
      selector (function CheckCommand f -> Some f | _ -> None) analyzer
    in
    let module Visitor = struct
      class ['a] iter = object
        inherit ['a] CST.iter

        method! visit_simple_command' _ c =
          let c' = command_of_simple_command c.value in
          let alarms' =
            List.flatmap (fun f -> f c.position c') command_filters
          in
          alarms := alarms' @ !alarms
      end
    end
    in
    fun script ->
      (new Visitor.iter)#visit_program () script;
      List.iter (fun f -> push (f script)) program_filters;
      !alarms

(** Analyzers combinators. *)

let for_all_command f = CheckCommand f

(** An argument is a word in command_suffix carrying its context
   represented by a zipper. *)
type argument = {
  on_left  : command_suffix_item list;
  focus    : word;
  on_right : command_suffix_item list;
}

let one_of xs pred =
  List.exists pred xs

let word_precedes arg item =
  match arg.on_left with
  | `Word { value = Word (item', _); _ } :: _ -> item = item'
  | _ -> false


let for_all_arguments command f =
  let rec iter on_left = function
    | [] ->
      []
    | (`Word word') as item :: on_right ->
      f word'.position { on_left; focus = word'.value; on_right }
      @ iter (item :: on_left) on_right
    | item :: on_right ->
      iter (item :: on_left) on_right
  in
  iter [] command.command_suffix

let check_argument arg pred =
  pred arg.focus

let is_not_quoted_word : word -> bool = function
  | Word (w, _) -> not (Str.(string_match (regexp "^\".*\"$") w 0))
