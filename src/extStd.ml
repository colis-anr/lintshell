module List =
struct
  include List
  let flatmap f l = flatten (map f l)
end

let indent d s =
  Str.(global_replace (regexp "^\\([^\n]\\)") (String.make d ' ' ^ "\\1") s)
