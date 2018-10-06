elm-global-data-example
=======================

This project demonstrates how to share globally cached data selectively across
pages in an SPA. `/profile` will be called on first load of the `/posts`
route, but then not again. It won't be called on `/comments`.

Grep the code base for `INTERESTING` for commentary on the ... interesting
bits.

Overall this is pretty quickly thrown together, so don't look to it for any
other best practices. It's roughly modeled after
[`elm-spa-example`](https://github.com/rtfeldman/elm-spa-example/), that's a
better place to look.

To run it:

    json-server --watch db.json
    elm-live src/Main.elm --pushstate
    # Visit localhost:8000/posts
