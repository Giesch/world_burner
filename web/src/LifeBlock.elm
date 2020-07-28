module LifeBlock exposing
    ( LifeBlock
    , SplitResult(..)
    , combine
    , paths
    , singleton
    , splitAt
    , view
    , warning
    )

import Creation.BeaconId as BeaconId exposing (DropBeaconId)
import Element exposing (..)
import Element.Border as Border
import Element.Input as Input
import Lifepath exposing (Lifepath)
import List.NonEmpty as NonEmpty exposing (NonEmpty)


{-| A non-empty linked list of lifepaths with beacon ids.
-}
type LifeBlock
    = LifeBlock (NonEmpty Lifepath)


paths : LifeBlock -> NonEmpty Lifepath
paths (LifeBlock list) =
    list


singleton : Lifepath -> LifeBlock
singleton path =
    LifeBlock <| NonEmpty.singleton path


append : LifeBlock -> LifeBlock -> LifeBlock
append (LifeBlock left) (LifeBlock right) =
    LifeBlock <| NonEmpty.append left right


{-| Validates whether the blocks can be combined in order.
-}
combine : LifeBlock -> LifeBlock -> Result String LifeBlock
combine left ((LifeBlock rightData) as right) =
    let
        rightFirst : Lifepath
        rightFirst =
            NonEmpty.head rightData
    in
    if rightFirst.born then
        Err "A 'born' lifepath must be a character's first lifepath"

    else
        Ok <| append left right


{-| Validation warning for an incomplete character
-}
warning : LifeBlock -> Maybe String
warning (LifeBlock ( first, _ )) =
    if first.born then
        Nothing

    else
        Just "A character's first lifepath must be a 'born' lifepath"


type SplitResult a
    = Whole a
    | Split ( a, a )
    | NotFound


{-| Splits a LifeBlock at the given index.
ie 0 would be taking the whole thing, while 'length' would be out of bounds.
-}
splitAt : LifeBlock -> Int -> SplitResult LifeBlock
splitAt (LifeBlock ( first, rest )) index =
    let
        list : List Lifepath
        list =
            first :: rest
    in
    case ( List.take index list, List.drop index list ) of
        ( leftFirst :: leftRest, rightFirst :: rightRest ) ->
            Split <|
                ( LifeBlock ( leftFirst, leftRest )
                , LifeBlock ( rightFirst, rightRest )
                )

        ( [], rightFirst :: rightRest ) ->
            Whole <| LifeBlock ( rightFirst, rightRest )

        ( _ :: _, [] ) ->
            NotFound

        ( [], [] ) ->
            -- this is impossible
            NotFound


type alias ViewOptions msg =
    { baseAttrs : List (Attribute msg)
    , dropBeaconOverride : Maybe DropBeaconId -- used during hover
    , onDelete : Maybe msg
    , benchIndex : Int
    }


view : ViewOptions msg -> LifeBlock -> Element msg
view { baseAttrs, dropBeaconOverride, onDelete, benchIndex } (LifeBlock data) =
    let
        dropZone id =
            el (BeaconId.dropAttribute id :: Border.width 1 :: baseAttrs)
                (el [ centerX, centerY ] <| text "+")

        fakeDropZone =
            el (Border.width 1 :: baseAttrs)
                (el [ centerX, centerY ] <| text "+")

        attrs =
            case dropBeaconOverride of
                Just id ->
                    BeaconId.dropAttribute id :: baseAttrs

                Nothing ->
                    baseAttrs

        withBeacon blockIndex =
            case dropBeaconOverride of
                Just _ ->
                    Nothing

                Nothing ->
                    Just <| BeaconId.benchDragId { benchIndex = benchIndex, blockIndex = blockIndex }

        middle =
            Input.button [ alignRight ]
                { onPress = onDelete
                , label = text "X"
                }
                :: List.indexedMap
                    (\blockIndex path -> Lifepath.view path { withBeacon = withBeacon blockIndex })
                    (NonEmpty.toList <| data)
    in
    column attrs <|
        case dropBeaconOverride of
            Just _ ->
                fakeDropZone :: middle ++ [ fakeDropZone ]

            Nothing ->
                dropZone (BeaconId.beforeSlotDropId benchIndex)
                    :: middle
                    ++ [ dropZone <| BeaconId.afterSlotDropId benchIndex ]
