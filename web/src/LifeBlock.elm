module LifeBlock exposing
    ( BlockData
    , LifeBlock
    , append
    , beaconId
    , paths
    , singleton
    , view
    , withBenchIndex
    )

import Beacon
import Common
import Creation.BeaconId as BeaconId exposing (DragBeaconId, DropBeaconId)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Lifepath exposing (Lifepath)
import List.NonEmpty as NonEmpty exposing (NonEmpty)


{-| A non-empty linked list of lifepaths with beacon ids.
Each beacon id is considered to apply to the whole list tail.
-}
type LifeBlock
    = LifeBlock (NonEmpty BlockData)


type alias BlockData =
    { path : Lifepath

    -- TODO remove this and add it to a view record type
    , beaconId : DragBeaconId
    }


paths : LifeBlock -> NonEmpty Lifepath
paths (LifeBlock list) =
    NonEmpty.map .path list


beaconId : LifeBlock -> DragBeaconId
beaconId (LifeBlock ( data, _ )) =
    data.beaconId


singleton : Lifepath -> DragBeaconId -> LifeBlock
singleton path id =
    LifeBlock <| NonEmpty.singleton { path = path, beaconId = id }


{-| TODO replace this with a split between a LifeBlock (no id) and a LifeBlockView (with id)
-}
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


{-| TODO should this module do validation when joining lists? ie return a result
-}
append : Int -> LifeBlock -> LifeBlock -> LifeBlock
append benchIndex (LifeBlock left) (LifeBlock right) =
    withBenchIndex benchIndex <| LifeBlock <| NonEmpty.append left right


type SplitResult a
    = Whole a
    | Split ( a, a )
    | NotFound


splitUntil : LifeBlock -> DragBeaconId -> SplitResult LifeBlock
splitUntil ((LifeBlock ( first, rest )) as original) id =
    case Common.splitUntil (\block -> block.beaconId == id) (first :: rest) of
        Nothing ->
            NotFound

        Just ( [], right ) ->
            Whole <| LifeBlock right

        Just ( leftFirst :: leftRest, right ) ->
            Split ( LifeBlock ( leftFirst, leftRest ), LifeBlock right )


type alias ViewOptions msg =
    { baseAttrs : List (Attribute msg)
    , dropBeaconId : Maybe DropBeaconId
    , onDelete : Maybe msg
    , benchIndex : Int
    }


view : ViewOptions msg -> LifeBlock -> Element msg
view { baseAttrs, dropBeaconId, onDelete, benchIndex } (LifeBlock data) =
    let
        dropZone id =
            el (BeaconId.dropAttribute id :: Border.width 1 :: baseAttrs)
                (el [ centerX, centerY ] <| text "+")

        attrs =
            case dropBeaconId of
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
        dropZone (BeaconId.beforeSlotDropId benchIndex)
            :: middle
            ++ [ dropZone <| BeaconId.afterSlotDropId benchIndex ]
