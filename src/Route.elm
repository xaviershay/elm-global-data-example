module Route exposing (Route(..), parseRoute, routeParser)

import Url.Parser exposing ((</>), Parser, int, map, oneOf, s, string)


type Route
    = Posts
    | Comments


parseRoute =
    Url.Parser.parse routeParser


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map Posts (s "posts")
        , map Comments (s "comments")
        ]
