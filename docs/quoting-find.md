- Name:    quoting/find
- Author:  Yann Régis-Gianas <yrg@irif.fr>
- Summary: Check that 'find' patterns are quoted.
- Description:
  In the following example:
  ```
  find -name *.c
  ```
  The glob *.c is expanded before the execution of find while it
  should be passed as a pattern to the 'name' argument:
  ```
  find -name '*.c'
  ```
