module Main exposing (Model)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Page.Comments
import Page.Posts
import Route
import Url


type alias Model =
    { key : Nav.Key
    , route : Route.Route
    , pageModel : PageModel
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


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    changeRouteTo Route.Posts (Model key Route.Posts Empty)


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
            Page.Posts.update subMsg subModel
                |> updateWith PostsModel GotPostsMsg model

        ( GotCommentsMsg subMsg, CommentsModel subModel ) ->
            Page.Comments.update subMsg subModel
                |> updateWith CommentsModel GotCommentsMsg model

        ( _, _ ) ->
            ( model, Cmd.none )


changeRouteTo : Route.Route -> Model -> ( Model, Cmd Msg )
changeRouteTo route model =
    case route of
        Route.Comments ->
            Page.Comments.init |> updateWith CommentsModel GotCommentsMsg model

        Route.Posts ->
            Page.Posts.init |> updateWith PostsModel GotPostsMsg model


updateWith : (subModel -> PageModel) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg model ( subModel, subCmd ) =
    ( { model | pageModel = toModel subModel }
    , Cmd.map toMsg subCmd
    )


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
    case model.pageModel of
        Empty ->
            viewPage [ text "You shouldn't be here" ]

        PostsModel subModel ->
            viewPage [ Page.Posts.view subModel, p [] [ viewLink "/comments" ] ]

        CommentsModel subModel ->
            viewPage [ Page.Comments.view subModel, p [] [ viewLink "/posts" ] ]


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
