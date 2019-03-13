# How to write a lintshell analyzer?

## Overview

To write a lintshell analyzer, first copy the directory `docs/template`.

In that fresh directory, there are 3 files:

- `checkSomething.ml` is the module that implements your analyzer.
- `dune` describes the structure of the lintshell plugin to build.
- `tests` contains scripts that contain something wrong detected by your analyzer.

As a result, we advise you to proceed as follows:

1. Create one or several script shells in `tests` that should generate alarms
   when processed by your analyzer.

2. Check that `lintshell check` does not already detect these flaws.

3. If not, find a name for your analyzer and rename `checkSomething.ml`
   and the `name` and `public_name` attributes of `dune` accordingly.

4. Implement your analysis in the renamed `checkSomething.ml`.
   (We will give more details about this step in the next section.)

5. `dune build install` will compile and install your plugin once
   it is a valid OCaml program.

6. Check that `lintshell list` now refers to your plugin.

7. Check that `lintshell check` now detects the flaws of all the files
   in `tests`.

8. (Optionally) Contribute to `lintshell` by creating a PR with this new plugin!

## How are analyzers implemented?

As illustrated by the initial contents of `checkSomething.ml`, an
analyzer is a module of signature `Analyzer.S`. Several metadata are
therefore mandatory: a name, a list of authors, a short and a long
descriptions and most importantly, a value of type `analyzer`.

There are many combinators to build analyzers, please refer to
the [interface](https://github.com/colis-anr/lintshell/blob/master/src/analyzer.mli)
for a complete description. In a nutshell, there are two families of combinators:

- *low-level combinators*: They allow you to write a function
  of type `t -> alarm list` where `t` is a concrete syntax
  tree (for the whole program or for a specific syntactic
  category) as defined in
  [Morbig CST module](https://github.com/colis-anr/morbig/blob/master/src/CST.ml) ;
  or `t` can be an abstract syntax tree as defined
  in [Morsmall AST module](https://github.com/colis-anr/morsmall/blob/master/src/AST.ml).

- *high-level combinators*: They allow you to describe
  some patterns in a POSIX script following a declarative style.

High-level combinators are always preferrable when they apply because
their applications can be combined in a single traversal of the syntax
tree. Low-level combinators are more expressive but each low-level
combinator requires a specific traversal of the syntax tree.
