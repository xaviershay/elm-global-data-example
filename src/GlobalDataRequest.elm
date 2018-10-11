module GlobalDataRequest exposing (GlobalDataRequest(..), Request(..), SharedModel, init, toRequests, update)

import Data.Profile
import Data.Profile2
import Http
import Status exposing (..)
import Task exposing (Task)



-- INTERESTING: This module encapsulates the different types of global data
-- that are "available" for pages to request, as well as mappings from the
-- abstract request type (`Profile`) to details that can be wrapped up by the
-- `Main` module to handle the requests. It's possible that a level of
-- indirection could be removed here, and the pages (via a function) refer
-- directly to the thing returned by `toRequests` rather than a `Request`.


type GlobalDataRequest
    = CompletedProfileRequest (Result Http.Error Data.Profile.Profile)
    | CompletedProfile2Request (Result Http.Error Data.Profile2.Profile2)


type Request
    = Profile
    | Profile2


type alias SharedModel =
    { profile : Status Data.Profile.Profile
    , profile2 : Status Data.Profile2.Profile2
    }


init =
    SharedModel Loading Loading


toRequests : SharedModel -> Request -> Maybe (Cmd GlobalDataRequest)
toRequests sharedModel req =
    case ( sharedModel, req ) of
        ( model, Profile ) ->
            case model.profile of
                Loaded x ->
                    -- Using Nothing rather than Cmd.none here since callers
                    -- need to be able to switch on it.
                    Nothing

                _ ->
                    Just (Http.send CompletedProfileRequest (Http.get "http://localhost:3000/profile" Data.Profile.decoder))

        ( model, Profile2 ) ->
            case model.profile2 of
                Loaded x ->
                    Nothing

                _ ->
                    Just (Http.send CompletedProfile2Request (Http.get "http://localhost:3000/profile" Data.Profile2.decoder))


update : GlobalDataRequest -> SharedModel -> ( SharedModel, Cmd GlobalDataRequest )
update subMsg subModel =
    case subMsg of
        CompletedProfileRequest (Err x) ->
            ( { subModel | profile = Failed x }, Cmd.none )

        CompletedProfileRequest (Ok x) ->
            ( { subModel | profile = Loaded x }, Cmd.none )

        CompletedProfile2Request (Err x) ->
            ( { subModel | profile2 = Failed x }, Cmd.none )

        CompletedProfile2Request (Ok x) ->
            ( { subModel | profile2 = Loaded x }, Cmd.none )
