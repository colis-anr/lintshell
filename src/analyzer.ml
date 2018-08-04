open Libmorbig.CST

type alarm = {
  position : position;
  message  : string;
}

type analyzer = complete_command_list -> alarm list

module type S = sig
  val name : string
  val documentation : string
  val analyzer : analyzer
end

let _analyzers : (module S) list ref = ref []
let analyzers () = !_analyzers

let register_analyzer (module Analyzer : S) =
  _analyzers := (module Analyzer) :: !_analyzers

let show_documentation (module Analyzer : S) =
  Printf.printf "%-30s %s\n"
    Analyzer.name
    Analyzer.documentation
