module Data.Profile exposing (Profile, decoder)

import Json.Decode as Decode


type alias Profile =
    { name : String
    }


decoder : Decode.Decoder Profile
decoder =
    Decode.map Profile
        (Decode.field "name" Decode.string)
