open Morbig.CST

type t = {
  position : position;
  message  : string;
}

let extract_from_file file from to_ =
  let buf = Buffer.create 8 in
  let ic = open_in file in
  let line = ref 1 in
  while !line < from do
    match input_char ic with
    | '\n' -> incr line
    | _ -> ()
  done;
  while !line <= to_ do
    let c = input_char ic in
    Buffer.add_char buf c;
    match c with
    | '\n' -> incr line
    | _ -> ()
  done;
  close_in ic;
  Buffer.contents buf

let report alarm =
  let filename = alarm.position.start_p.pos_fname in
  let line = alarm.position.start_p.pos_lnum in
  let first_column = alarm.position.start_p.pos_cnum - alarm.position.start_p.pos_bol in
  let last_column = alarm.position.end_p.pos_cnum - alarm.position.end_p.pos_bol in
  Format.printf "\nFile \"%s\", line %d:\n: %s  %s%s\n%s@."
    filename line
    (extract_from_file filename line line)
    (String.make first_column ' ')
    (String.make (last_column - first_column) '^')
    alarm.message

let make ~position message =
  { position ; message }
