module Page.Comments exposing (Model, Msg(..), Status(..), init, update, view)

import Data.Comment exposing (Comment)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode


type Status a
    = Loading
    | Loaded a
    | Failed Http.Error


type Msg
    = CompletedCommentsRequest (Result Http.Error (List Comment))


type alias Model =
    { comments : Status (List Comment)
    }


init : ( Model, Cmd Msg )
init =
    ( { comments = Loading }
    , Cmd.batch
        [ Http.send CompletedCommentsRequest (Http.get "http://localhost:3000/comments" (Decode.list Data.Comment.decoder))
        ]
    )


update msg model sharedModel =
    case msg of
        CompletedCommentsRequest (Err e) ->
            ( { model | comments = Failed e }, Cmd.none )

        CompletedCommentsRequest (Ok comments) ->
            ( { model | comments = Loaded comments }, Cmd.none )


view model sharedModel =
    case model.comments of
        Failed x ->
            p [] [ text "Failed: ", text (Debug.toString x) ]

        Loading ->
            text "Loading"

        Loaded comments ->
            ul [] (List.map (\x -> li [] [ text x.body ]) comments)
