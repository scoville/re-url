# ReUrl

ReUrl is a port of the [elm-url](https://github.com/elm/url) library, a powerful Url parser and builder.

## Simple example

```rescript

// We can define our Route module
module Route = {
  open UrlParser // Must be open! UrlParser if you use the `/` operator

  // It will contain an exhaustive list of possible routes, with arguments
  // Notice that we use `deriving(accessors)` for conveniency, but you don't have to
  @deriving(accessors)
  type t = Home | Blog(int) | Something(string, int) | NotFound

  // We can now define our 3 possible paths
  let topRoute = top->map(home)

  let blogRoute = (s("blog") / int())->map(blog)

  // Even complex routes are still easy to read:
  let somethingRoute = (s("something") / str() / s("else") / (int())->map(something)

  // This function will take a string and try to decode/parse it using one of the provided parsers
  // If no paths match, then the fallback value will be returned
  let fromString = oneOf([topRoute, blogRoute, somethingRoute])->parseString(~fallback=notFound)
}

// You might use some existing library like the bs-webapi
// Any string value would work anyway
@val @scope(("window", "location"))
external currentUrl: string = "href"

// The core logic of our router,
// it can be used to display some components conditionally in React for example
Js.log(
  switch Route.fromString(currentUrl) {
  | Home => "Home page"
  | Blog(id) => `Blog page with id ${id->Int.toString}`
  | Something(x, y) => `Found this ${x} and that ${y->Int.toString}`
  | NotFound => "Page not found"
  },
)
```

The [`test`](test/Url_Test.res) file contains an example for most of the provided functions.

## Known current limitations

- The QueryParser module is not implemented currently
- Syntaxically, ReScript doesn't allow [yet](https://github.com/rescript-lang/syntax/pull/220) for custom operators. Once it does, we could imagine this syntax to define the `somethingRoute` from above:

```rescript
let somethingRoute = (s("something") </> str() </> s("else") </> int())->map(something)
```

- If you define a parser and don't use it, or if you use the parser _outside_ the module where the route type `t` is defined, you will encounter one of these errors (using the same Route module as above):

```rescript
module Route = {
  let blogRoute = s("blog") / int()
  // Raises a `The type of this module contains type variables that cannot be generalized`
  // compile error, and later: `let blogRoute: Url.UrlParser.parser<int => '_weak1, '_weak1>`
}

// When trying to use the above parser outside the module, while it seems it should solve the weak
// polymorphism issue, it actually introduces an other error:
Route.blogRoute->UrlParser.parseString(~fallback=Route.notFound, url)
// Will raise `The type constructor Route.t would escape its scope` compile error
```

You can check the OCaml [documentation](https://ocamlverse.github.io/content/weak_type_variables.html) explains the first limitation pretty well.

The limitations can be hard to lift upstream, and should be handled downstream, in your application. _It's worth noticing that these type errors won't happen if you follow the canonical example above._
