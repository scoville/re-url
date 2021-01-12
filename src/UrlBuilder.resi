type queryParameter

type root = [#absolute | #relative | #crossOrigin(string)]

let toQuery: array<queryParameter> => string

let absolute: (~paths: array<string>=?, ~queryParameters: array<queryParameter>=?, unit) => string

let relative: (~paths: array<string>=?, ~queryParameters: array<queryParameter>=?, unit) => string

let crossOrigin: (
  ~baseUrl: string,
  ~paths: array<string>=?,
  ~queryParameters: array<queryParameter>=?,
  unit,
) => string

let custom: (
  root,
  ~paths: array<string>=?,
  ~queryParameters: array<queryParameter>=?,
  ~fragment: string=?,
  unit,
) => string

module Query: {
  let string: (~key: string, ~value: string) => queryParameter

  let int: (~key: string, ~value: int) => queryParameter
}
