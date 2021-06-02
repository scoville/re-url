let flatMapArray = (xs, f) => xs->Array.reduce([], (acc, x) => acc->Array.concat(f(x)))

type state<'a> = {
  visited: list<string>,
  unvisited: list<string>,
  params: Map.String.t<array<string>>,
  frag: option<string>,
  value: 'a,
}

// Primitives

type rec parser<'a, 'b> = Parser(state<'a> => array<state<'b>>)

let custom = (_type: string, fromString) => Parser(
  ({visited, unvisited, params, frag, value}) =>
    switch unvisited {
    | list{} => []
    | list{next, ...rest} =>
      switch fromString(next) {
      | Some(nextValue) => [
          {
            visited: list{next, ...visited},
            unvisited: rest,
            params: params,
            frag: frag,
            value: value(nextValue),
          },
        ]
      | None => []
      }
    },
)

let str = () => custom("STRING", x => Some(x))

let int = () => custom("NUMBER", Int.fromString)

let s = (type a, path): parser<a, a> => Parser(
  ({visited, unvisited, params, frag, value}) =>
    switch unvisited {
    | list{} => []
    | list{next, ...rest} =>
      if next == path {
        [
          {
            visited: list{next, ...visited},
            unvisited: rest,
            params: params,
            frag: frag,
            value: value,
          },
        ]
      } else {
        []
      }
    },
)

// Path

let slash = (Parser(parseBefore), Parser(parseAfter)) => Parser(
  state => state->parseBefore->flatMapArray(parseAfter),
)

let mapState = ({visited, unvisited, params, frag, value}, f) => {
  visited: visited,
  unvisited: unvisited,
  params: params,
  frag: frag,
  value: f(value),
}

let oneOf = parsers => Parser(state => parsers->flatMapArray((Parser(parser)) => parser(state)))

let top = Parser(state => [state])

// Queries

let query = (UrlParserQuery.Parser(queryParser)) => Parser(
  ({visited, unvisited, params, frag, value}) => [
    {
      visited: visited,
      unvisited: unvisited,
      params: params,
      frag: frag,
      value: value(queryParser(params)),
    },
  ],
)

// <?>
let q = (parser, queryParser) => slash(parser, query(queryParser))

// Fragments

let fragment = toFragment => Parser(
  ({visited, unvisited, params, frag, value}) => [
    {
      visited: visited,
      unvisited: unvisited,
      params: params,
      frag: frag,
      value: value(toFragment(frag)),
    },
  ],
)

// Utilities

let map = (Parser(parseArg), subValue) => Parser(
  ({visited, unvisited, params, frag, value}) =>
    {visited: visited, unvisited: unvisited, params: params, frag: frag, value: subValue}
    ->parseArg
    ->Array.map(state => state->mapState(value)),
)

// Run Parsers

let rec removeFinalEmpty = segments =>
  switch segments {
  | list{} | list{""} => list{}
  | list{segment, ...rest} => list{segment, ...removeFinalEmpty(rest)}
  }

let preparePath = path =>
  switch path->Js.String2.split("/")->List.fromArray {
  | list{"", ...segments} => segments->removeFinalEmpty
  | segments => segments->removeFinalEmpty
  }

let rec getFirstMatch = states =>
  switch states {
  | list{} => None
  | list{{value, unvisited}, ...rest} =>
    switch unvisited {
    | list{} | list{""} => Some(value)
    | _ => getFirstMatch(rest)
    }
  }

let addToParametersHelp = (value, values) =>
  switch values {
  | None => Some([value])
  | Some(values) => Some([value]->Js.Array2.concat(values))
  }

let addParam = (dict, path) =>
  switch path->Js.String2.split("=") {
  | [rawKey, rawValue] =>
    switch (Js.Global.decodeURIComponent(rawKey), Js.Global.decodeURIComponent(rawValue)) {
    | exception _ => dict
    | (key, value) => dict->Map.String.update(key, addToParametersHelp(value))
    }
  | _ => dict
  }

let prepareQuery = query =>
  switch query {
  | None => Map.String.empty
  | Some(query) => query->Js.String2.split("&")->Array.reduce(Map.String.empty, addParam)
  }

let parse = (Parser(parser), {Url.fragment: fragment, path, query}) =>
  {
    visited: list{},
    unvisited: path->preparePath,
    params: query->prepareQuery,
    frag: fragment,
    value: value => value,
  }
  ->parser
  ->List.fromArray
  ->getFirstMatch

let parseString = (parser, url, ~fallback) =>
  switch url->Url.fromString {
  | None => fallback
  | Some(url) => parser->parse(url)->Option.getWithDefault(fallback)
  }
