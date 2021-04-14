type parser<'a> = Parser(Map.String.t<array<string>> => 'a)

let custom = (key, f) => Parser(map => map->Map.String.getWithDefault(key, [])->f)

let str = key => custom(key, strs => strs[0])

let int = key => custom(key, strs => strs[0]->Option.flatMap(Int.fromString))

let enum = (key, values) =>
  custom(key, strs => strs[0]->Option.flatMap(str => Js.Dict.fromArray(values)->Js.Dict.get(str)))

let map = (Parser(a), f) => Parser(map => f(a(map)))

let pure = value => Parser(_ => value)

let apply = (Parser(a), Parser(f)) => Parser(map => f(map, a(map)))
