type parser<'a> = Parser(Map.String.t<array<string>> => 'a)

// Primitives

let custom = (key, f) => Parser(map => map->Map.String.getWithDefault(key, [])->f)

let str = key => custom(key, strs => strs[0])

let int = key => custom(key, strs => strs[0]->Option.flatMap(Int.fromString))

let enum = (key, values) =>
  custom(key, strs => strs[0]->Option.flatMap(str => Js.Dict.fromArray(values)->Js.Dict.get(str)))

// Utilities

// Same as `pure`
let from = value => Parser(_ => value)

let map = (Parser(a), f) => Parser(map => f(a(map)))

// Same as `apply`
let search = (Parser(f), Parser(a)) => Parser(map => f(map, a(map)))

let withDefault = (Parser(a), default) => Parser(map => a(map)->Option.getWithDefault(default))
