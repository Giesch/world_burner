module Common exposing
    ( SplitResult
    , keepIf
    , minimumBy
    , splitAt
    , userSelectNone
    )

import Element
import Html.Attributes
import List.NonEmpty exposing (NonEmpty)


{-| Splits a NonEmpty list at the given index.

splitAt 0 ( 1, [2, 3, 4] )
=> Whole ( 1, [2, 3, 4] )

splitAt 2 ( 1, [2, 3, 4] )
=> Split ( ( 1, [2] ), ( 3, [4] ) )

splitAt 4 ( 1, [2, 3, 4] )
=> None

splitAt -1 ( 1, [2, 3, 4] )
=> Whole ( 1, [2, 3, 4] )

splitAt 5 ( 1, [2, 3, 4] )
=> None

-}
splitAt : Int -> NonEmpty a -> SplitResult a
splitAt index ( first, rest ) =
    let
        list : List a
        list =
            first :: rest
    in
    case ( List.take index list, List.drop index list ) of
        ( left, rightFirst :: rightRest ) ->
            Just ( left, ( rightFirst, rightRest ) )

        _ ->
            Nothing


type alias SplitResult a =
    Maybe ( List a, NonEmpty a )


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
