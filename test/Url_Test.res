let url = "https://www.example.com:2002/foo/bar?key=val#some-fragment"

// Url.fromString
assert (
  url->Url.fromString ==
    Some({
      Url.protocol: #https,
      host: "www.example.com",
      port: Some(2002),
      path: "/foo/bar",
      query: Some("key=val"),
      fragment: Some("some-fragment"),
    })
)

// Url.toString (idempotency)
assert (url->Url.fromString->Option.mapWithDefault("", Url.toString) == url)

// UrlBuilder.absolute
assert (UrlBuilder.absolute() == "/")
assert (UrlBuilder.absolute(~paths=["packages", "elm", "core"], ()) == "/packages/elm/core")
assert (UrlBuilder.absolute(~paths=["blog", 42->Int.toString], ()) == "/blog/42")
assert (
  UrlBuilder.absolute(
    ~paths=["products"],
    ~queryParameters=[
      UrlBuilder.Query.string(~key="search", ~value="hat"),
      UrlBuilder.Query.int(~key="page", ~value=2),
    ],
    (),
  ) == "/products?search=hat&page=2"
)

// UrlBuilder.relative
assert (UrlBuilder.relative(~paths=[], ()) == "")
assert (UrlBuilder.relative(~paths=[], ~queryParameters=[], ()) == "")
assert (UrlBuilder.relative(~paths=["packages", "elm", "core"], ()) == "packages/elm/core")
assert (UrlBuilder.relative(~paths=["blog", 42->Int.toString], ()) == "blog/42")
assert (
  UrlBuilder.relative(
    ~paths=["products"],
    ~queryParameters=[
      UrlBuilder.Query.string(~key="search", ~value="hat"),
      UrlBuilder.Query.int(~key="page", ~value=2),
    ],
    (),
  ) == "products?search=hat&page=2"
)

// UrlBuilder.crossOrigin
assert (
  UrlBuilder.crossOrigin(
    ~baseUrl="https://example.com",
    ~paths=["products"],
    (),
  ) == "https://example.com/products"
)
assert (UrlBuilder.crossOrigin(~baseUrl="https://example.com", ()) == "https://example.com/")
assert (
  UrlBuilder.crossOrigin(
    ~baseUrl="https://example.com:8042",
    ~paths=["over", "there"],
    ~queryParameters=[UrlBuilder.Query.string(~key="name", ~value="ferret")],
    (),
  ) == "https://example.com:8042/over/there?name=ferret"
)

// UrlBuilder.custom
assert (
  UrlBuilder.custom(
    #absolute,
    ~paths=["packages", "elm", "core", "latest", "String"],
    ~fragment="length",
    (),
  ) == "/packages/elm/core/latest/String#length"
)
assert (
  UrlBuilder.custom(
    #relative,
    ~paths=["there"],
    ~queryParameters=[UrlBuilder.Query.string(~key="name", ~value="ferret")],
    (),
  ) == "there?name=ferret"
)
assert (
  UrlBuilder.custom(
    #crossOrigin("https://example.com:8042"),
    ~paths=["over", "there"],
    ~queryParameters=[UrlBuilder.Query.string(~key="name", ~value="ferret")],
    ~fragment="nose",
    (),
  ) == "https://example.com:8042/over/there?name=ferret#nose"
)

module Route = {
  open UrlParser

  @deriving(accessors)
  type t = Home | Blog(int) | Something(string, int) | About | NotFound

  let topRoute = top
  let blogRoute = s("blog")->slash(int())
  let somethingRoute = s("something")->slash(str())->slash(s("else"))->slash(int())
  let aboutRoute = s("about")

  let fromString =
    oneOf([
      topRoute->map(home),
      blogRoute->map(blog),
      somethingRoute->map(something),
      aboutRoute->map(about),
    ])->parseString(~fallback=notFound)
}

assert (Route.fromString("/blog/42") == NotFound)
assert (Route.fromString("https://example.com/") == Home)
assert (Route.fromString("https://example.com/blog/42") == Blog(42))
assert (Route.fromString("https://example.com/blog/foo") == NotFound)
assert (Route.fromString("https://example.com/something/foo/else/12") == Something("foo", 12))
assert (Route.fromString("https://example.com/something/foo/else/bar") == NotFound)
assert (Route.fromString("https://example.com/about") == About)

module RouteWithQueries = {
  open UrlParser
  module Query = UrlParserQuery

  type pickyQuery = X | Y

  type multiQuery = {foo: string, bar: int}

  @deriving(accessors)
  type t =
    | Home
    | Blog(int, option<string>)
    | Picky(option<pickyQuery>)
    | AlwaysMatch(int)
    | MultiQuery(multiQuery)
    | NotFound

  let multiQuery' =
    Query.from((foo, bar) => {foo: foo, bar: bar})
    ->Query.search(Query.str("foo")->Query.withDefault(""))
    ->Query.search(Query.int("bar")->Query.withDefault(0))

  let topRoute = top
  let blogRoute = s("blog")->slash(int())->q(Query.str("s"))
  let pickyRoute = s("picky")->q(Query.enum("value", [("x", X), ("y", Y)]))
  let alwaysMatchRoute =
    s("always-match")->q(Query.int("x")->Query.map(Option.getWithDefault(_, 0)))
  let multiQueryRoute = s("multi-query")->q(multiQuery')

  let fromString =
    oneOf([
      topRoute->map(home),
      blogRoute->map(blog),
      pickyRoute->map(picky),
      alwaysMatchRoute->map(alwaysMatch),
      multiQueryRoute->map(multiQuery),
    ])->parseString(~fallback=notFound)
}

assert (RouteWithQueries.fromString("https://example.com/blog/42") == Blog(42, None))
assert (RouteWithQueries.fromString("https://example.com/blog/42?no=thing") == Blog(42, None))
assert (
  RouteWithQueries.fromString("https://example.com/blog/42?s=thing") == Blog(42, Some("thing"))
)
assert (RouteWithQueries.fromString("https://example.com/picky") == Picky(None))
assert (RouteWithQueries.fromString("https://example.com/picky?value=wrong") == Picky(None))
assert (RouteWithQueries.fromString("https://example.com/picky?value=x") == Picky(Some(X)))
assert (RouteWithQueries.fromString("https://example.com/picky?value=y") == Picky(Some(Y)))
assert (RouteWithQueries.fromString("https://example.com/always-match?x=foo") == AlwaysMatch(0))
assert (RouteWithQueries.fromString("https://example.com/always-match") == AlwaysMatch(0))
assert (RouteWithQueries.fromString("https://example.com/always-match?x=1") == AlwaysMatch(1))
assert (RouteWithQueries.fromString("https://example.com/always-match?x=2000") == AlwaysMatch(2000))
assert (
  RouteWithQueries.fromString("https://example.com/multi-query?foo=hello&bar=42") ==
    MultiQuery({foo: "hello", bar: 42})
)
assert (
  RouteWithQueries.fromString("https://example.com/multi-query?foo=hello") ==
    MultiQuery({foo: "hello", bar: 0})
)
assert (
  RouteWithQueries.fromString("https://example.com/multi-query?bar=42") ==
    MultiQuery({foo: "", bar: 42})
)
assert (
  RouteWithQueries.fromString("https://example.com/multi-query") == MultiQuery({foo: "", bar: 0})
)
assert (
  RouteWithQueries.fromString("https://example.com/multi-query?foo=42&bar=hello") ==
    MultiQuery({foo: "42", bar: 0})
)

module RouteWithFragment = {
  open UrlParser

  @deriving(accessors)
  type t = Home | Blog(int, option<string>) | NotFound

  let topRoute = top
  let blogRoute = s("blog")->slash(int())->slash(fragment(x => x))

  let fromString =
    oneOf([topRoute->map(home), blogRoute->map(blog)])->parseString(~fallback=notFound)
}

assert (
  RouteWithFragment.fromString("https://example.com/blog/42#foobar") == Blog(42, Some("foobar"))
)
assert (RouteWithFragment.fromString("https://example.com/blog/42#") == Blog(42, Some("")))
assert (RouteWithFragment.fromString("https://example.com/blog/42") == Blog(42, None))

Js.log("Tests passed")
