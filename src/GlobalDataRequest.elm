module GlobalDataRequest exposing (GlobalDataRequest(..), Request(..), toRequests, update)

import Data.Profile
import Http
import Status exposing (..)



-- INTERESTING: This module encapsulates the different types of global data
-- that are "available" for pages to request, as well as mappings from the
-- abstract request type (`Profile`) to details that can be wrapped up by the
-- `Main` module to handle the requests. It's possible that a level of
-- indirection could be removed here, and the pages (via a function) refer
-- directly to the thing returned by `toRequests` rather than a `Request`.


type GlobalDataRequest
    = CompletedProfileRequest (Result Http.Error Data.Profile.Profile)


type Request
    = Profile


toRequests sharedModel req =
    case ( sharedModel, req ) of
        ( Loaded _, _ ) ->
            Nothing

        ( _, Profile ) ->
            Just ( CompletedProfileRequest, Http.get "http://localhost:3000/profile" Data.Profile.decoder )


update subMsg =
    case subMsg of
        CompletedProfileRequest (Err x) ->
            ( Failed x, Cmd.none )

        CompletedProfileRequest (Ok x) ->
            ( Loaded x, Cmd.none )
