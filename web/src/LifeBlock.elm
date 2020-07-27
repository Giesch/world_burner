module LifeBlock exposing
    ( BlockData
    , LifeBlock
    , SplitResult(..)
    , append
    , firstBeaconId
    , paths
    , singleton
    , splitUntil
    , view
    , withBenchIndex
    )

import Common
import Creation.BeaconId as BeaconId exposing (DragBeaconId, DropBeaconId)
import Element exposing (..)
import Element.Border as Border
import Element.Input as Input
import Lifepath exposing (Lifepath)
import List.NonEmpty as NonEmpty exposing (NonEmpty)


{-| A non-empty linked list of lifepaths with beacon ids.
-}
type LifeBlock
    = LifeBlock (NonEmpty BlockData)


{-| A lifepath and a drag beacon id.
Dragging a lifepath should also drag the tail of the block.
-}
type alias BlockData =
    { path : Lifepath
    , beaconId : DragBeaconId
    }


paths : LifeBlock -> NonEmpty Lifepath
paths (LifeBlock list) =
    NonEmpty.map .path list


firstBeaconId : LifeBlock -> DragBeaconId
firstBeaconId (LifeBlock ( data, _ )) =
    data.beaconId


singleton : Lifepath -> DragBeaconId -> LifeBlock
singleton path id =
    LifeBlock <| NonEmpty.singleton { path = path, beaconId = id }


withBenchIndex : Int -> LifeBlock -> LifeBlock
withBenchIndex benchIndex (LifeBlock list) =
    let
        makeId blockIndex =
            BeaconId.benchDragId <| { benchIndex = benchIndex, blockIndex = blockIndex }
    in
    LifeBlock <|
        NonEmpty.indexedMap
            (\i data -> { data | beaconId = makeId i })
            list


append : Int -> LifeBlock -> LifeBlock -> LifeBlock
append benchIndex (LifeBlock left) (LifeBlock right) =
    withBenchIndex benchIndex <| LifeBlock <| NonEmpty.append left right


type SplitResult a
    = Whole a
    | Split ( a, a )
    | NotFound


splitUntil : LifeBlock -> DragBeaconId -> SplitResult LifeBlock
splitUntil (LifeBlock ( first, rest )) id =
    case Common.splitUntil (\block -> block.beaconId == id) (first :: rest) of
        Nothing ->
            NotFound

        Just ( [], right ) ->
            Whole <| LifeBlock right

        Just ( leftFirst :: leftRest, right ) ->
            Split ( LifeBlock ( leftFirst, leftRest ), LifeBlock right )


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

        middle =
            Input.button [ alignRight ]
                { onPress = onDelete
                , label = text "X"
                }
                :: List.map
                    (\d -> Lifepath.view d.path { withBeacon = Just d.beaconId })
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
