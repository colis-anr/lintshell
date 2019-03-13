- Name:    variables/parameters
- Author:  Yann Régis-Gianas <yrg@irif.fr>
- Summary: Check that variables parameters are valid.
- Description:
  In *2.6.2 Parameter Expansion* of the POSIX standard:

  - `${#parameter}` **String Length**.
    The length in characters of the value of parameter shall be substituted.
    If parameter is `*` or `@`, the result of the expansion is unspecified.
    If parameter is unset and `set -u` is in effect, the expansion shall fail.

  Therefore, `${#*}` and `${#@}` are deprecated.
