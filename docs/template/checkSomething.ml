Lintshell.Analyzer.(register_analyzer (module struct

  let name = "quoting/find"

  let authors = ["Yann Régis-Gianas <yrg@irif.fr>"]

  let short_description = "Check that 'find' patterns are quoted."

  let documentation =
"
In the following example:
```
find -name *.c
```
The glob *.c is expanded before the execution of find while it
should be passed as a pattern to the 'name' argument:
```
find -name '*.c'
```
"

  let find_pattern_commands = ["-name"]

  let message = "Patterns of the find command must be quoted."

  let analyzer =
    for_all_command ~name:"find" (fun _ c ->
        for_all_arguments c (fun pos arg ->
            Alarm.at pos message (
              one_of find_pattern_commands (word_precedes arg) &&
              check_argument arg is_not_quoted_word)
          )
      )
end))
