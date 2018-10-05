module Data.Comment exposing (Comment, decoder)

import Json.Decode as Decode


type alias Comment =
    { body : String
    , id : Int
    }


decoder : Decode.Decoder Comment
decoder =
    Decode.map2 Comment
        (Decode.field "body" Decode.string)
        (Decode.field "id" Decode.int)
