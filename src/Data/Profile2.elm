-- This is a copy of Profile, but exposed as a different type so we can ensure
-- we have our type constraints correct.


module Data.Profile2 exposing (Profile2, decoder)

import Json.Decode as Decode


type alias Profile2 =
    { name : String
    }


decoder : Decode.Decoder Profile2
decoder =
    Decode.map Profile2
        (Decode.field "name" Decode.string)
