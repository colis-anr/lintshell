Lintshell.Analyzer.(register_analyzer (module struct

  let name = "category/something-is-wrong"

  let authors = ["KT <kt@unix.forever>"]

  let short_description = "Check if something is wrong."

  let documentation =
"
Something can be wrong in your script. Let me explain what!
"

  let message = "Something is wrong here."

  let analyzer =
    for_all_command (fun pos _c ->
        Alarm.at pos message (
            true
          )
      )
end))
