(** An analysis is a value of type [analyzer]. *)
type analyzer

(** {1 Plugin infrastructure} *)

(** To define a plugin, a value of type [analyzer] must be decorated
    by metadata, as specified by the following module signature. *)
module type S =
  sig
    (** A name must be of the form "category/something" where
       "something" is what is checked by this analyzer. *)
    val name : string

    (** Use the format "Don Knuth <dk@nemail.no>" *)
    val authors : string list

    (** A summary must be shorter than 20 characters. *)
    val short_description : string

    (** [documentation] is written in markdown. *)
    val documentation : string

    val analyzer : analyzer
  end

(** This function must be called by every plugin to let it
    know to the lintshell tool. *)
val register_analyzer : (module S) -> unit

(** The list of analyzers known by lintshell. *)
val analyzers : unit -> (module S) list

val name : (module S) -> string

val show_short_description : (module S) -> unit

val show_details : (module S) -> unit

(** {1 What is an analyzer?} *)

(** An analyzer can traverse concrete syntax trees, getting all the
    details about the source code syntactic recognition. *)
module Concrete = Morbig.CST

(** An analyzer can also traverse abstract syntax trees, which forgets
   about some details of the source code but are significantly simpler
   that concrete syntax trees. *)
module Abstract = Morsmall.AST

(** An analyzer must produce an alarm for each flaw it detects. *)
module Alarm : sig
  type t
  val compare : t -> t -> int
  val report : t -> unit
  val make : position:Concrete.position -> string -> t
  val at: Concrete.position -> string -> bool -> t list
end

type alarms = Alarm.t list

val interpret : analyzer -> Concrete.program -> Abstract.program -> alarms

(** {1 Composition combinators} *)

(** Analyzers can be combined. Notice however that high-level
   combinators combine in a more efficient way in general since they
   can be merged in a common traversal of the syntax tree. *)
val sequence : analyzer list -> analyzer

(** {1 Low-level combinators} *)

val check_program :
  (Concrete.program -> alarms) ->
  analyzer

val check_abstract_program :
  (Abstract.program -> alarms) ->
  analyzer

val check_word_component :
  (Concrete.position -> Concrete.word_component -> alarms) ->
  analyzer

(** {1 High-level combinators} *)

type command

type argument

val for_all_command :
  ?name:string ->
  (Concrete.position -> command -> alarms) -> analyzer

val for_all_arguments :
  command -> (Concrete.position -> argument -> 'a list) -> 'a list

val word_precedes : argument -> string -> bool

val check_argument : argument -> (Concrete.word -> 'a) -> 'a

(** {1 Handy predicates} *)

val one_of : 'a list -> ('a -> bool) -> bool

val equal_word : string -> Concrete.word -> bool

val is_not_quoted_word : Concrete.word -> bool
