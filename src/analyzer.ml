module type CommonAnalyzer = sig
  val name : string
  val description : string
end

module type CSTAnalyzer = sig
  include CommonAnalyzer
  val analyze : Morbig.CST.program -> Alarm.t list
end

module type ASTAnalyzer = sig
  include CommonAnalyzer
  val analyze : Morsmall.AST.program -> Alarm.t list
end

type t =
  | CSTAnalyzer of (module CSTAnalyzer)
  | ASTAnalyzer of (module ASTAnalyzer)

let analyzers : t list ref = ref []
let get_analyzers () = List.rev !analyzers

let register_cst_analyzer (module CSTAnalyzer : CSTAnalyzer) =
  analyzers := (CSTAnalyzer (module CSTAnalyzer)) :: !analyzers

let register_ast_analyzer (module ASTAnalyzer : ASTAnalyzer) =
  analyzers := (ASTAnalyzer (module ASTAnalyzer)) :: !analyzers

let unwrap = function
  | CSTAnalyzer (module CSTAnalyzer) -> (module CSTAnalyzer : CommonAnalyzer)
  | ASTAnalyzer (module ASTAnalyzer) -> (module ASTAnalyzer : CommonAnalyzer)

let name analyzer =
  let (module Analyzer) = unwrap analyzer in
  Analyzer.name

let description analyzer =
  let (module Analyzer) = unwrap analyzer in
  Analyzer.description

let analyze analyzer cst ast =
  match analyzer with
  | CSTAnalyzer (module CSTAnalyzer) -> CSTAnalyzer.analyze cst
  | ASTAnalyzer (module ASTAnalyzer) -> ASTAnalyzer.analyze ast

let pp fmt analyzer =
  let (module Analyzer) = unwrap analyzer in
  Format.fprintf fmt "%-30s %s\n"
    Analyzer.name Analyzer.description
