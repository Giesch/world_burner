module Creation.Status exposing
    ( Status(..)
    , map
    )

import Creation.BeaconId exposing (dropLocation)


type Status a
    = Loading
    | Loaded a
    | Failed


map : (a -> b) -> Status a -> Status b
map fn status =
    case status of
        Loading ->
            Loading

        Failed ->
            Failed

        Loaded a ->
            Loaded (fn a)
