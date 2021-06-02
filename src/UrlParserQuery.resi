type parser<'a> = Parser(Map.String.t<array<string>> => 'a)

// Primitives

let custom: (string, array<string> => 'a) => parser<'a>

let str: string => parser<option<string>>

let int: string => parser<option<int>>

let enum: (string, array<(string, 'a)>) => parser<option<'a>>

// Utilities

let from: 'a => parser<'a>

let map: (parser<'a>, 'a => 'b) => parser<'b>

let search: (parser<'a => 'b>, parser<'a>) => parser<'b>

let withDefault: (parser<option<'a>>, 'a) => parser<'a>
