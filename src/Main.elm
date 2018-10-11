module Main exposing (Model)

import Browser
import Browser.Navigation as Nav
import Data.Profile
import Either exposing (..)
import GlobalDataRequest exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Page.Comments
import Page.Posts
import Route
import Status exposing (..)
import Url


type alias Model =
    { key : Nav.Key
    , route : Route.Route
    , pageModel : PageModel

    -- INTERESTING: I cheated here a bit and directly emdedded this data as the
    -- shared model. You can imagine wrapping this in a type to allow for
    -- different types for shared data.
    , sharedModel : GlobalDataRequest.SharedModel

    -- INTERESTING: This list of messages will be processed whenever a
    -- successful shared data request completes. It is set by the init function
    -- whenever we change a page.
    --
    -- See README for discussion of other methods of managing this list.
    , sharedCallback : List Msg
    }


type PageModel
    = PostsModel Page.Posts.Model
    | CommentsModel Page.Comments.Model
    | Empty -- This is pretty gross. Should be home or something.


type Msg
    = LinkClicked Browser.UrlRequest
    | ChangedUrl Url.Url
    | GotPostsMsg Page.Posts.Msg
    | GotCommentsMsg Page.Comments.Msg
      -- INTERESTING: Wrapping GlobalDataRequest here primarily to avoid a
      -- dependency loop (pages can depend on GlobalDataRequest rather than
      -- Main), but as a nice side effect this also packages up the global data
      -- requests into a separate module to avoid changes in Main when new ones
      -- are added.
    | GotGlobalDataMsg GlobalDataRequest


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    changeRouteTo Route.Posts (Model key Route.Posts Empty GlobalDataRequest.init [])


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.pageModel ) of
        ( ChangedUrl url, _ ) ->
            case Route.parseRoute url of
                Just x ->
                    changeRouteTo x model

                Nothing ->
                    Debug.todo "no route found"

        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        ( GotPostsMsg subMsg, PostsModel subModel ) ->
            Page.Posts.update subMsg subModel model.sharedModel
                |> updateWith PostsModel GotPostsMsg model

        ( GotCommentsMsg subMsg, CommentsModel subModel ) ->
            Page.Comments.update subMsg subModel model.sharedModel
                |> updateWith CommentsModel GotCommentsMsg model

        -- INTERESTING: This message handler looks very similar to the page
        -- handlers above. Neat, huh?
        ( GotGlobalDataMsg subMsg, _ ) ->
            let
                ( newSharedModel, newCmd ) =
                    GlobalDataRequest.update subMsg model.sharedModel

                newModel =
                    { model | sharedModel = newSharedModel }

                ( newSubModel, newCmd2 ) =
                    -- INTERESTING: Recursively call update here rather
                    -- than dispatch another Cmd. See
                    -- https://medium.com/elm-shorts/how-to-turn-a-msg-into-a-cmd-msg-in-elm-5dd095175d84
                    List.foldl
                        (\callback ( modelAccum, cmdAccum ) ->
                            let
                                ( m2, c2 ) =
                                    update callback modelAccum
                            in
                            ( m2, Cmd.batch [ cmdAccum, c2 ] )
                        )
                        ( newModel, Cmd.none )
                        newModel.sharedCallback
            in
            ( newSubModel
            , Cmd.batch
                [ Cmd.map GotGlobalDataMsg newCmd
                , newCmd2
                ]
            )

        ( _, _ ) ->
            ( model, Cmd.none )


changeRouteTo : Route.Route -> Model -> ( Model, Cmd Msg )
changeRouteTo route model =
    case route of
        Route.Comments ->
            Page.Comments.init |> updateInitWith CommentsModel GotCommentsMsg model

        Route.Posts ->
            Page.Posts.init |> updateInitWith PostsModel GotPostsMsg model


catMaybes =
    List.filterMap identity


updateWith : (subModel -> PageModel) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg model ( subModel, subCmd ) =
    ( { model | pageModel = toModel subModel }
    , Cmd.map toMsg subCmd
    )


updateInitWith : (subModel -> PageModel) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg, List ( Request, subMsg ) ) -> ( Model, Cmd Msg )
updateInitWith toModel toMsg model ( subModel, subCmd, reqs ) =
    let
        -- INTERESTING: In addition to their own init, pages return a list of
        -- what shared data they are interested in (GlobalDataRequest.Request),
        -- and a callback subMsg they want to receive when that data is loaded.
        --
        -- This mangling transforms that Request into a (Cmd
        -- GlobalDataRequest), the callback subMsg into a (Msg), then composes
        -- them both together into a (Msg | GotGlobalDataMsg).
        --
        -- You can imagine extending this interface allow for optional
        -- callbacks (have subpage init function return a (Maybe subMsg)).
        --
        -- If the shared data is already loaded, then rather than generate a
        -- new command (the Right case), we instead need to directly recurse
        -- into update with the callback message (Left case). It's tempting to
        -- instead wrap the callback message up into a Cmd and dispatch it,
        -- since it would make this code cleaner, but that has weaker
        -- guarantees around ordering (see
        -- https://medium.com/elm-shorts/how-to-turn-a-msg-into-a-cmd-msg-in-elm-5dd095175d84).
        -- Doing it this way is more correct. This recursion idea is also used
        -- above in the message handler for GotGlobalDataMsg.
        --
        -- TODO: Simplify this by _always_ calling the callback, even if not loaded
        -- yet. It's slightly more work, but the callback has to handle this case
        -- anyway and it's probably worth it for the code simplification.
        sharedCmds =
            List.map
                (\( req, callback ) ->
                    case GlobalDataRequest.toRequests model.sharedModel req of
                        Nothing ->
                            Left (toMsg callback)

                        Just reqCmd ->
                            Right
                                ( toMsg callback
                                , Cmd.map
                                    GotGlobalDataMsg
                                    reqCmd
                                )
                )
                reqs
    in
    -- Using the shared data requests as an initial value, iterate through
    -- all the direct callbacks (where data has been loaded) and include
    -- their results in our final model/cmd pair.
    --
    -- TODO: Abstract this foldl pattern, we use it in a couple of places.
    List.foldl
        (\callback ( accumModel, cmd ) ->
            let
                ( m2, cmd2 ) =
                    update callback accumModel
            in
            ( m2, Cmd.batch [ cmd, cmd2 ] )
        )
        ( { model | pageModel = toModel subModel, sharedCallback = List.map Tuple.first (rights sharedCmds) }
        , Cmd.batch
            [ Cmd.map toMsg subCmd

            -- If sharedCmds is empty, this will be a noop
            , Cmd.batch (List.map Tuple.second (rights sharedCmds))
            ]
        )
        (lefts sharedCmds)


view : Model -> Browser.Document Msg
view model =
    let
        viewPage body =
            { title = "Test App"
            , body = body
            }
    in
    case model.pageModel of
        Empty ->
            viewPage [ text "You shouldn't be here" ]

        PostsModel subModel ->
            viewPage [ Page.Posts.view subModel model.sharedModel, p [] [ viewLink "/comments" ] ]

        CommentsModel subModel ->
            viewPage [ Page.Comments.view subModel model.sharedModel, p [] [ viewLink "/posts" ] ]


viewLink : String -> Html msg
viewLink path =
    a [ href path ] [ text path ]


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
        , onUrlChange = ChangedUrl
        , onUrlRequest = LinkClicked
        }
