open Morbig.CST

let _ = Lintshell.Analyzer.(register_analyzer (module struct

  let name = "variables/parameters"

  let authors = ["Yann Régis-Gianas <yrg@irif.fr>"]

  let short_description = "Check that variables parameters are valid."

  let documentation =
"
In *2.6.2 Parameter Expansion* of the POSIX standard:

- `${#parameter}` **String Length**.
  The length in characters of the value of parameter shall be substituted.
  If parameter is `*` or `@`, the result of the expansion is unspecified.
  If parameter is unset and `set -u` is in effect, the expansion shall fail.

Therefore, `${#*}` and `${#@}` are deprecated.
"

  let message = "The expansions of ${#*} and ${#@} are unspecified."

  let unspecified_variable_parameter = function
    | WordVariable (VariableAtom (_, ParameterLength w)) ->
       equal_word "*" w || equal_word "@" w
    | _ ->
       false

  let analyzer =
    check_word_component (fun pos c ->
        Alarm.at pos message (
            unspecified_variable_parameter c
        )
      )

end))
