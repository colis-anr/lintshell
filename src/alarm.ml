open Libmorbig.CST

type t = {
  position : position;
  message  : string;
}

let extract_from_file p1 p2 =
  let open Lexing in
  let buf = Bytes.make (p2.pos_cnum - p1.pos_bol) ' ' in
  let ic = open_in p1.pos_fname in
  seek_in ic p1.pos_bol; (*FIXME: cnum; ?*)
  really_input ic buf (p1.pos_cnum - p1.pos_bol) (p2.pos_cnum - p1.pos_cnum);
  close_in ic;
  Bytes.to_string buf

let report alarm =
  Format.printf "In %s line %d:\n%s@."
    alarm.position.start_p.pos_fname
    alarm.position.start_p.pos_lnum
    (extract_from_file alarm.position.start_p alarm.position.end_p)
