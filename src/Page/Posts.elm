module Page.Posts exposing (Model, Msg(..), Post, Status(..), decoder, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode


type Status a
    = Loading
    | Loaded a
    | Failed Http.Error


type alias Post =
    { title : String
    , author : String
    , id : Int
    }


type Msg
    = CompletedPostsRequest (Result Http.Error (List Post))


type alias Model =
    { posts : Status (List Post)
    }


init : ( Model, Cmd Msg )
init =
    ( { posts = Loading }
    , Cmd.batch
        [ Http.send CompletedPostsRequest (Http.get "http://localhost:3000/posts" decoder)
        ]
    )


update msg model =
    case msg of
        CompletedPostsRequest (Err e) ->
            ( { model | posts = Failed e }, Cmd.none )

        CompletedPostsRequest (Ok posts) ->
            ( { model | posts = Loaded posts }, Cmd.none )


view model =
    case model.posts of
        Failed x ->
            p [] [ text "Failed: ", text (Debug.toString x) ]

        Loading ->
            text "Loading"

        Loaded posts ->
            ul [] (List.map (\x -> li [] [ text x.title ]) posts)


decoder : Decode.Decoder (List Post)
decoder =
    Decode.list <|
        Decode.map3 Post
            (Decode.field "title" Decode.string)
            (Decode.field "author" Decode.string)
            (Decode.field "id" Decode.int)
