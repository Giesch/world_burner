module Common exposing
    ( keepIf
    , minimumBy
    , userSelectNone
    )

import Element
import Html.Attributes


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
