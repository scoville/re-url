type protocol = [#http | #https]

type t = {
  protocol: protocol,
  host: string,
  port: option<int>,
  path: string,
  query: option<string>,
  fragment: option<string>,
}

let toString: t => string

let fromString: string => option<t>
