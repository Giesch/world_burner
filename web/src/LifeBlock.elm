module LifeBlock exposing
    ( LifeBlock
    , SplitResult(..)
    , combine
    , paths
    , singleton
    , splitAt
    , view
    )

import Creation.BeaconId as BeaconId exposing (DragBeaconId, DropBeaconId)
import Element exposing (..)
import Element.Border as Border
import Element.Input as Input
import Lifepath exposing (Lifepath)
import Lifepath.Validation as Validation
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


{-| Validates whether the blocks can be combined in order.
-}
combine : LifeBlock -> LifeBlock -> Result String LifeBlock
combine left ((LifeBlock rightData) as right) =
    let
        append : LifeBlock -> LifeBlock -> LifeBlock
        append (LifeBlock l) (LifeBlock r) =
            LifeBlock <| NonEmpty.append l r

        rightFirst : Lifepath
        rightFirst =
            NonEmpty.head rightData
    in
    if rightFirst.born then
        Err "A 'born' lifepath must be a character's first lifepath"

    else
        Ok <| append left right


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
view { baseAttrs, dropBeaconOverride, onDelete, benchIndex } (LifeBlock lifepaths) =
    let
        dropZone : DropBeaconId -> Element msg
        dropZone id =
            case dropBeaconOverride of
                Just _ ->
                    el (Border.width 1 :: baseAttrs)
                        (el [ centerX, centerY ] <| text "+")

                Nothing ->
                    el (BeaconId.dropAttribute id :: Border.width 1 :: baseAttrs)
                        (el [ centerX, centerY ] <| text "+")

        attrs : List (Attribute msg)
        attrs =
            List.filterMap identity [ warnAttr, dropAttr ] ++ baseAttrs

        dropAttr : Maybe (Attribute msg)
        dropAttr =
            dropBeaconOverride
                |> Maybe.map BeaconId.dropAttribute

        warnAttr : Maybe (Attribute msg)
        warnAttr =
            case dropBeaconOverride of
                Just _ ->
                    Nothing

                Nothing ->
                    Validation.warnings lifepaths
                        |> viewWarnings
                        |> Maybe.map Element.onRight

        withBeacon : Int -> Maybe DragBeaconId
        withBeacon blockIndex =
            case dropBeaconOverride of
                Just _ ->
                    Nothing

                Nothing ->
                    Just <| BeaconId.benchDragId { benchIndex = benchIndex, blockIndex = blockIndex }

        middle : List (Element msg)
        middle =
            Input.button [ alignRight ]
                { onPress = onDelete
                , label = text "X"
                }
                :: List.indexedMap
                    (\blockIndex path -> Lifepath.view { withBeacon = withBeacon blockIndex } path)
                    (NonEmpty.toList lifepaths)
    in
    column attrs <|
        dropZone (BeaconId.beforeSlotDropId benchIndex)
            :: middle
            ++ [ dropZone <| BeaconId.afterSlotDropId benchIndex ]


viewWarnings : List Validation.Warning -> Maybe (Element msg)
viewWarnings warns =
    let
        viewWarn (Validation.Warning msg) =
            text msg
    in
    case warns of
        [] ->
            Nothing

        nonEmpty ->
            Just <| column [] <| List.map viewWarn nonEmpty
