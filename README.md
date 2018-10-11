elm-global-data-example
=======================

This project demonstrates how to share globally cached data selectively across
pages in an SPA. `/profile` will be called on first load of the `/posts`
route, but then not again. It won't be called on `/comments`.

In addition, it also shows how pages are able to build up their own model as a
result of that shared data.

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

This was developed on elm 0.19.

Failure cases
-------------

Rapidly switching between pages can trigger duplicate shared data requests.
What happens when these arrive out of order? What happens if one fails after
one has succeeded?

The first successful shared data request will always update the active page,
subsequent ones should be no-ops. Since shared data will always be applied
whenever a page is navigated to, we don't need to worry about updating
non-active pages that historically requested the shared data - that update is
effectively deffered until the page is navigated to again. (In theory it
wouldn't be hard to also update non-active pages, but not sure the extra
bookkeepping to do so - keeping a list of pages that need callbacks - provides
any benefits).

It is possible that a callback will be called multiple times for the same
shared data, that's fine and expected: should be a noop on repeat calls.

This implementation redundantly generates duplicate shared data requests when
one is already in flight but hasn't completed yet. This doesn't affect
correctness (we need to handle possible duplicate requests anyway, for example
if we ever want to be able to retry on error), but could be addressed by some
extra bookkeeping in the Status data type.
