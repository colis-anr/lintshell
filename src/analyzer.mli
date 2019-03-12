type t

val name : t -> string
val description : t -> string
val analyze : t -> Morbig.CST.program -> Morsmall.AST.program -> Alarm.t list

val pp : Format.formatter -> t -> unit

(** {2 Registering and getting registered analyzers} *)

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

val register_cst_analyzer : (module CSTAnalyzer) -> unit
val register_ast_analyzer : (module ASTAnalyzer) -> unit

val get_analyzers : unit -> t list
