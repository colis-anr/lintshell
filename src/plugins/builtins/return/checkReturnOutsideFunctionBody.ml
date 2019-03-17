Lintshell.Analyzer.(register_analyzer (module struct

  let name = "builtins/return"

  let authors = ["Yann Régis-Gianas <yrg@irif.fr>"]

  let short_description = "Check that 'return' is used inside a function body."

  let documentation =
    "
     The POSIX standard says:

 ```
 The return utility shall cause the shell to stop executing the \
 current function or dot script. If the shell is not currently \
 executing a function or dot script, the results are unspecified.
```
"

  let message =
    "The behavior of `return` outside a function or dot script is unspecified."

  let analyzer =
    for_all_command ~name:"return" (fun pos c ->
            Alarm.at pos message (not (command_inside_function_body c)))

end))
