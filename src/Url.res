// TODO: Implement our own parser logic
module NativeUrl = {
  type t = {
    auth: Js.Nullable.t<string>,
    hash: Js.Nullable.t<string>,
    host: Js.Nullable.t<string>,
    hostname: Js.Nullable.t<string>,
    href: string,
    path: Js.Nullable.t<string>,
    pathname: Js.Nullable.t<string>,
    protocol: Js.Nullable.t<string>,
    search: Js.Nullable.t<string>,
    slashes: Js.Nullable.t<bool>,
    port: Js.Nullable.t<string>,
    query: Js.Nullable.t<string>,
  }

  @module("native-url") external parse: string => t = "parse"

  @module("native-url") external format: t => string = "format"
}

type protocol = [#http | #https]

type t = {
  protocol: protocol,
  host: string,
  port: option<int>,
  path: string,
  query: option<string>,
  fragment: option<string>,
}

let fromNativeUrl = ({NativeUrl.protocol: protocol, hostname, port, pathname, query, hash}) => {
  let convert = (protocol, hostname) => {
    protocol: protocol,
    host: hostname,
    port: port->Js.Nullable.toOption->Option.flatMap(Int.fromString),
    path: pathname->Js.Nullable.toOption->Option.getWithDefault(""),
    query: query->Js.Nullable.toOption,
    fragment: hash->Js.Nullable.toOption->Option.map(hash => hash->Js.String2.sliceToEnd(~from=1)),
  }

  switch (protocol->Js.Nullable.toOption, hostname->Js.Nullable.toOption) {
  | (Some("http:"), Some(hostname)) => Some(convert(#http, hostname))
  | (Some("https:"), Some(hostname)) => Some(convert(#https, hostname))
  | _ => None
  }
}

let toNativeUrl = ({protocol, host, port, path, query, fragment}) => {
  let port = port->Option.map(Int.toString)
  let portWithColon = port->Option.mapWithDefault("", port => `:${port}`)
  let search = query->Option.map(query => `?${query}`)

  {
    NativeUrl.auth: Js.Nullable.null,
    hash: fragment->Option.map(fragment => `#${fragment}`)->Js.Nullable.fromOption,
    host: `${host}${portWithColon}`->Js.Nullable.return,
    hostname: host->Js.Nullable.return,
    // Lost in the conversion
    href: "",
    path: `${path}${search->Option.getWithDefault("")}`->Js.Nullable.return,
    pathname: path->Js.Nullable.return,
    protocol: switch protocol {
    | #http => "http:"
    | #https => "https:"
    }->Js.Nullable.return,
    search: search->Js.Nullable.fromOption,
    query: query->Js.Nullable.fromOption,
    slashes: true->Js.Nullable.return,
    port: port->Js.Nullable.fromOption,
  }
}

let toString = url => url->toNativeUrl->NativeUrl.format

let fromString = str => str->NativeUrl.parse->fromNativeUrl
