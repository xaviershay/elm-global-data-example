module Status exposing (Status(..))

import Http


type Status a
    = Loading
    | Loaded a
    | Failed Http.Error
