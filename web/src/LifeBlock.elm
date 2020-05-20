module LifeBlock exposing
    ( BlockData
    , LifeBlock
    , beaconId
    , paths
    , singleton
    , view
    )

import Beacon
import Common
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
    , beaconId : Int
    }


paths : LifeBlock -> NonEmpty Lifepath
paths (LifeBlock list) =
    NonEmpty.map .path list


beaconId : LifeBlock -> Int
beaconId (LifeBlock ( data, _ )) =
    data.beaconId


singleton : Lifepath -> Int -> LifeBlock
singleton path id =
    LifeBlock <| NonEmpty.singleton { path = path, beaconId = id }


{-| TODO should this module do validation when joining lists?
ie return an either
-}
append : LifeBlock -> LifeBlock -> LifeBlock
append (LifeBlock left) (LifeBlock right) =
    LifeBlock <| NonEmpty.append left right


type SplitResult a
    = Whole a
    | Split ( a, a )
    | NotFound


splitUntil : LifeBlock -> Int -> SplitResult LifeBlock
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
    , dropBeaconId : Maybe Int
    , onDelete : Maybe msg
    }


view : ViewOptions msg -> LifeBlock -> Element msg
view { baseAttrs, dropBeaconId, onDelete } (LifeBlock data) =
    let
        attrs =
            case dropBeaconId of
                Just id ->
                    Beacon.attribute id :: baseAttrs

                Nothing ->
                    baseAttrs
    in
    column attrs <|
        Input.button [ alignRight ]
            { onPress = onDelete
            , label = text "X"
            }
            :: List.map
                (\d -> Lifepath.view d.path { withBeacon = Just d.beaconId })
                (NonEmpty.toList <| data)
