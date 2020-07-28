module Common exposing
    ( keepIf
    , minimumBy
    , userSelectNone
    , withBothOk
    )

import Element
import Html.Attributes


{-| AKA Result.andThen2 (with the function last)
The left error is returned if both results fail.
-}
withBothOk : Result e a -> Result e b -> (a -> b -> Result e value) -> Result e value
withBothOk left right fn =
    case ( left, right ) of
        ( Ok a, Ok b ) ->
            fn a b

        ( Err e, _ ) ->
            Err e

        ( _, Err e ) ->
            Err e


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
