type queryParameter = QueryParameter(string, string)

type root = [#absolute | #relative | #crossOrigin(string)]

let toQueryPair = (QueryParameter(key, value)) => `${key}=${value}`

let toQuery = queryParameters =>
  switch queryParameters {
  | [] => ""
  | _ => `?${queryParameters->Array.map(toQueryPair)->Js.Array2.joinWith("&")}`
  }

let relative = (~paths=[], ~queryParameters=[], ()) =>
  `${paths->Js.Array2.joinWith("/")}${toQuery(queryParameters)}`

let absolute = (~paths=[], ~queryParameters=[], ()) => `/${relative(~paths, ~queryParameters, ())}`

let crossOrigin = (~baseUrl, ~paths=[], ~queryParameters=[], ()) =>
  `${baseUrl}${absolute(~paths, ~queryParameters, ())}`

let rootToPrePath = root =>
  switch root {
  | #absolute => "/"
  | #relative => ""
  | #crossOrigin(baseUrl) => `${baseUrl}/`
  }

let custom = (root, ~paths=[], ~queryParameters=[], ~fragment=?, ()) => {
  let urlWithoutFragment = `${rootToPrePath(root)}${paths->Js.Array2.joinWith("/")}${toQuery(
      queryParameters,
    )}`

  switch fragment {
  | None => urlWithoutFragment
  | Some(fragment) => `${urlWithoutFragment}#${fragment}`
  }
}

module Query = {
  let string = (~key, ~value) => QueryParameter(
    Js.Global.encodeURIComponent(key),
    Js.Global.encodeURIComponent(value),
  )

  let int = (~key, ~value) => QueryParameter(Js.Global.encodeURIComponent(key), value->Int.toString)
}
