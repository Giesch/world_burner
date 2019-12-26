module Common exposing (..)

import Dict exposing (Dict)


{-| AKA Maybe.filter
-}
keepIf : (a -> Bool) -> Maybe a -> Maybe a
keepIf pred =
    Maybe.andThen
        (\something ->
            if pred something then
                Just something

            else
                Nothing
        )


{-| Flipped Dict.get
-}
lookup : Dict comparable v -> comparable -> Maybe v
lookup =
    flip Dict.get


flip : (a -> b -> c) -> b -> a -> c
flip fn b a =
    fn a b
