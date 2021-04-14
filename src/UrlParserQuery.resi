type parser<'a> = Parser(Map.String.t<array<string>> => 'a)

let custom: (string, array<string> => 'a) => parser<'a>

let str: string => parser<option<string>>

let int: string => parser<option<int>>

let enum: (string, array<(string, 'a)>) => parser<option<'a>>

let map: (parser<'a>, 'a => 'b) => parser<'b>

let pure: 'a => parser<'a>

let apply: (parser<'a>, parser<'a => 'b>) => parser<'b>
