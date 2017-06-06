# lintshell, a user-extensible lint for POSIX shell

## Description

lintshell analyzes the concrete syntax trees produced by the morbig
parser to look for potential programming errors.

lintshell is user-extensible: anyone can program an analysis and
integrate it in the tools.

## Requirements

   - ocaml     (>= 4.03.0)
   - libmorbig (>= 0.1)
