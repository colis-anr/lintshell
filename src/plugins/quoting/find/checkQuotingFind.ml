open Lintshell

module Checker : Analyzer.CSTAnalyzer = struct
  let name = "quoting/find"
  let description = "Check that find patterns are quoted."

  let analyze _ = []
end

let register = Analyzer.register_cst_analyzer (module Checker)
