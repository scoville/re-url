type parser<'a>

let str: string => parser<option<string>>

let str: string => parser<option<int>>

let enum: (string, Js.Dict.t<'a>) => parser<option<'a>>

let custom: (string, array<string> => 'a) => parser<'a>

let map: (parser<'a>, 'a => 'b) => parser<'b>
