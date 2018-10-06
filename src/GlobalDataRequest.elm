module GlobalDataRequest exposing (GlobalDataRequest(..), Request(..), toRequests, update)

import Data.Profile
import Http
import Status exposing (..)


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
