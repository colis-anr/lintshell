# lintshell, a user-extensible lint for POSIX shell

## Description

lintshell analyzes the syntax trees produced by the morbig
parser to look for potential programming errors.

lintshell is user-extensible: anyone can program an analysis and
integrate it into the tool.

## Installation

Type `opam install lintshell`

## Requirements

   - ocaml  (>= 4.03.0)
   - morbig (>= 0.10.3)

## Usage

- `lintshell list` displays the [docs/analyzers.md](list of installed analyzers).
- `lintshell check script` analyzes POSIX shell `script`.
- `lintshell show analyzer` displays a description of `analyzer`.

## Want to write your own analyzer?

Please read this [docs/how-to-write-a-lintshell-analyzer.md](file)?
