module Common exposing (..)

import Dict exposing (Dict)
import Element
import Html.Attributes
import List.NonEmpty as NonEmpty exposing (NonEmpty)


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


{-| Splits a list into a left of all leading values that do not satisify the predicate,
and a right of the first value that satisfied the predicate, and the remaining elements.
Returning nothing means that no matching item was found.
-}
splitUntil : (a -> Bool) -> List a -> Maybe ( List a, NonEmpty a )
splitUntil pred list =
    let
        seek : ( List a, List a ) -> Maybe ( List a, NonEmpty a )
        seek ( seen, unseen ) =
            case unseen of
                [] ->
                    Nothing

                first :: rest ->
                    if pred first then
                        Just ( List.reverse seen, ( first, rest ) )

                    else
                        seek ( first :: seen, rest )
    in
    seek ( [], list )


userSelectNone : List (Element.Attribute msg)
userSelectNone =
    List.map (\key -> Element.htmlAttribute <| Html.Attributes.style key "none")
        [ "-webkit-touch-callout"
        , "-webkit-user-select"
        , "-khtml-user-select"
        , "-moz-user-select"
        , "-ms-user-select"
        , "user-select"
        ]
