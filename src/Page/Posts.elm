module Page.Posts exposing (Model, Msg(..), init, update, view)

import Data.Post exposing (Post)
import GlobalDataRequest
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode
import Status exposing (..)


type Msg
    = CompletedPostsRequest (Result Http.Error (List Post))
    | SharedDataUpdated


type alias Model =
    { posts : Status (List Post)
    , profileName : String
    }


init : ( Model, Cmd Msg, List ( GlobalDataRequest.Request, Msg ) )
init =
    ( { posts = Loading, profileName = "" }
    , Http.send CompletedPostsRequest (Http.get "http://localhost:3000/posts" (Decode.list Data.Post.decoder))
      -- INTERESTING: This is all the posts page needs to do to request that
      -- the global profile data be present.
    , [ ( GlobalDataRequest.Profile, SharedDataUpdated ) ]
    )


update msg model sharedModel =
    case msg of
        CompletedPostsRequest (Err e) ->
            ( { model | posts = Failed e }, Cmd.none )

        CompletedPostsRequest (Ok posts) ->
            ( { model | posts = Loaded posts }, Cmd.none )

        -- INTERESTING: This callback allows the post to update it's own model based on
        -- shared model data.
        SharedDataUpdated ->
            let
                newModel =
                    case sharedModel.profile of
                        Loaded x ->
                            { model | profileName = x.name }

                        _ ->
                            { model | profileName = "Loading..." }
            in
            ( newModel, Cmd.none )


view model _ =
    let
        -- INTERESTING: I didn't go so far as to extract rendering of shared
        -- data into a shared module, but it would be trivial.
        profileView =
            p [] [ text "Profile: ", text model.profileName ]

        --    case sharedModel.profile of
        --        Loaded x ->
        --            p [] [ text "Profile: ", text x.name ]
        --        _ ->
        --            p [] [ text "Profile not loaded" ]
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
