# lintshell, a user-extensible lint for POSIX shell

## Description

lintshell analyzes the syntax trees produced by the morbig
parser to look for potential programming errors.

lintshell is user-extensible: anyone can program an analysis and
integrate it into the tool.

## Installation

### Via OPAM

After the first release, there will be an OPAM package and
`opam install lintshell` will be sufficient.

One can install the latest development version with:

    opam pin lintshell.dev https://github.com/colis-anr/lintshell.git

Or manually by:

1. cloning this repository and `cd`-ing to it;
1. installing the dependencies: `opam install . --deps-only`
1. building lintshell: `make`
1. playing with it: `bin/lintshell [...]`
1. installing it: `make install`

## Requirements

- ocaml  (≥ 4.03.0)
- morbig (≥ 0.10.3)

## Usage

- `lintshell list` displays the [list of installed analyzers](docs/analyzers.md).
- `lintshell check script` analyzes POSIX shell `script`.
- `lintshell show analyzer` displays a description of `analyzer`.

## Want to write your own analyzer?

Please read this [file](docs/how-to-write-a-lintshell-analyzer.md)?
