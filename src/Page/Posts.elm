module Page.Posts exposing (Model, Msg(..), Post(..), Status(..), init, update)


type Status a
    = Loading
    | Loaded a
    | Failed


type Post
    = String


type Msg
    = CompletedPostsRequest


type alias Model =
    { posts : Status (List Post)
    }


init : ( Model, Cmd Msg )
init =
    ( { posts = Loading }, Cmd.none )


update msg model =
    case msg of
        CompletedPostsRequest ->
            ( model, Cmd.none )
