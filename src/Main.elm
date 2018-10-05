module Main exposing (Model)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Url
import Url.Parser exposing ((</>), Parser, int, map, oneOf, s, string)


type Route
    = Posts
    | Comments


type alias Model =
    { key : Nav.Key
    , route : Route
    }


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model key Posts, Cmd.none )


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map Posts (s "posts")
        , map Comments (s "comments")
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged url ->
            case Url.Parser.parse routeParser url of
                Just x ->
                    ( { model | route = x }, Cmd.none )

                Nothing ->
                    Debug.todo "no route found"

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )


viewLink : String -> Html msg
viewLink path =
    a [ href path ] [ text path ]


view : Model -> Browser.Document Msg
view model =
    let
        viewPage body =
            { title = "Test App"
            , body = body
            }
    in
    case model.route of
        Posts ->
            viewPage [ text "Posts", viewLink "/comments" ]

        Comments ->
            viewPage [ text "Comments", viewLink "/posts" ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }
