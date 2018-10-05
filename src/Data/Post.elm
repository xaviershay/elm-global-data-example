module Data.Post exposing (Post, decoder)

import Json.Decode as Decode


type alias Post =
    { title : String
    , author : String
    , id : Int
    }


decoder : Decode.Decoder Post
decoder =
    Decode.map3 Post
        (Decode.field "title" Decode.string)
        (Decode.field "author" Decode.string)
        (Decode.field "id" Decode.int)
