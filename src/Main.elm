module Main exposing (Model)

import Browser
import Browser.Navigation as Nav
import Data.Profile
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
    changeRouteTo Route.Posts (Model key Route.Posts Empty GlobalDataRequest.init)


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
            in
            ( { model | sharedModel = newSharedModel }, Cmd.map GotGlobalDataMsg newCmd )

        ( _, _ ) ->
            ( model, Cmd.none )


changeRouteTo : Route.Route -> Model -> ( Model, Cmd Msg )
changeRouteTo route model =
    let
        ( newModel, newCmd, reqs ) =
            case route of
                Route.Comments ->
                    Page.Comments.init |> updateInitWith CommentsModel GotCommentsMsg model

                Route.Posts ->
                    Page.Posts.init |> updateInitWith PostsModel GotPostsMsg model

        -- INTERESTING: Pages return which global data they're interested in,
        -- this mangling transforms them into a request we know what to do
        -- with. Note the building of an Http req and wrapping in
        -- GotGlobalDataMsg
        globalDataReqs =
            List.map (GlobalDataRequest.toRequests model.sharedModel) reqs
    in
    ( newModel, Cmd.batch (newCmd :: List.map (Cmd.map GotGlobalDataMsg) globalDataReqs) )


catMaybes =
    List.filterMap identity


updateWith : (subModel -> PageModel) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg model ( subModel, subCmd ) =
    ( { model | pageModel = toModel subModel }
    , Cmd.map toMsg subCmd
    )


updateInitWith toModel toMsg model ( subModel, subCmd, reqs ) =
    ( { model | pageModel = toModel subModel }
    , Cmd.map toMsg subCmd
    , reqs
    )


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
