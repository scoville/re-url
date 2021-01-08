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
  type t = Home | Blog(int) | Something(string, int) | NotFound

  let topRoute = top->map(home)

  let blogRoute = s("blog")->slash(int())->map(blog)

  let somethingRoute = s("something")->slash(str())->slash(s("else"))->slash(int())->map(something)

  let fromString = oneOf([topRoute, blogRoute, somethingRoute])->parseString(~fallback=notFound)
}

assert (Route.fromString("/blog/42") == NotFound)
assert (Route.fromString("https://example.com/") == Home)
assert (Route.fromString("https://example.com/blog/42") == Blog(42))
assert (Route.fromString("https://example.com/blog/foo") == NotFound)
assert (Route.fromString("https://example.com/something/foo/else/12") == Something("foo", 12))
assert (Route.fromString("https://example.com/something/foo/else/bar") == NotFound)

Js.log("Tests passed")
