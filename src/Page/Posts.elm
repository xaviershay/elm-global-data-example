module Page.Posts exposing (Model, Msg(..), init, update, view)

import Data.Post exposing (Post)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode
import Status exposing (..)


type Msg
    = CompletedPostsRequest (Result Http.Error (List Post))


type alias Model =
    { posts : Status (List Post)
    }


init : ( Model, Cmd Msg )
init =
    ( { posts = Loading }
    , Cmd.batch
        [ Http.send CompletedPostsRequest (Http.get "http://localhost:3000/posts" (Decode.list Data.Post.decoder))
        ]
    )


update msg model sharedModel =
    case msg of
        CompletedPostsRequest (Err e) ->
            ( { model | posts = Failed e }, Cmd.none )

        CompletedPostsRequest (Ok posts) ->
            ( { model | posts = Loaded posts }, Cmd.none )


view model sharedModel =
    let
        profileView =
            case sharedModel of
                Loaded x ->
                    p [] [ text "Profile: ", text x.name ]

                _ ->
                    p [] [ text "Profile not loaded" ]
    in
    div []
        [ profileView
        , case model.posts of
            Failed x ->
                p [] [ text "Failed: ", text (Debug.toString x) ]

            Loading ->
                text "Loading"

            Loaded posts ->
                ul [] (List.map (\x -> li [] [ text x.title ]) posts)
        ]
