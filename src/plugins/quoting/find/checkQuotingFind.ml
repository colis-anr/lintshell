open Lintshell

module Checker : Analyzer.S = struct
  let documentation = "Check that find patterns are quoted."
  let name = "quoting/find"
  let analyzer _ = []
end

let register = Analyzer.register_analyzer (module Checker)
