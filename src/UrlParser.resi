type rec parser<_, _>

// Primitives

let custom: (string, string => option<'a>) => parser<'a => 'b, 'b>

let str: unit => parser<string => 'a, 'a>

let int: unit => parser<int => 'a, 'a>

let s: string => parser<'a, 'a>

// Path

let slash: (parser<'a, 'b>, parser<'b, 'c>) => parser<'a, 'c>

let \"/": (parser<'a, 'b>, parser<'b, 'c>) => parser<'a, 'c>

let map: (parser<'a, 'b>, 'a) => parser<'b => 'c, 'c>

let oneOf: array<parser<'a, 'b>> => parser<'a, 'b>

let top: parser<'a, 'a>

// Queries

// <?>
let q: unit

let query: unit

// Fragments

let fragment: unit

// Run Parsers

let parse: (parser<'a => 'a, 'a>, Url.t) => option<'a>

let parseString: (parser<'a => 'a, 'b>, string, ~fallback: 'b) => 'b
