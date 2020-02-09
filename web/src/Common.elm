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


lookup : Dict comparable v -> comparable -> Maybe v
lookup =
    flip Dict.get


flip : (a -> b -> c) -> (b -> a -> c)
flip fn a b =
    fn b a


type MissingValues id
    = MissingValues (List id)


lookupAll :
    Dict comparable v
    -> List comparable
    -> Result (MissingValues comparable) (List v)
lookupAll dict ids =
    let
        ( missing, present ) =
            List.foldl
                (\id ( unfound, found ) ->
                    case Dict.get id dict of
                        Just value ->
                            ( unfound, value :: found )

                        Nothing ->
                            ( id :: unfound, found )
                )
                ( [], [] )
                ids
    in
    case missing of
        [] ->
            Ok (List.reverse present)

        missingIds ->
            Err (MissingValues missingIds)


minimumBy : (a -> comparable) -> List a -> Maybe a
minimumBy by list =
    let
        keepLower left right =
            if compare (by left) (by right) == GT then
                right

            else
                left
    in
    case list of
        [] ->
            Nothing

        first :: rest ->
            Just <| List.foldl keepLower first rest
