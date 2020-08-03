module LifeBlock exposing
    ( Hover(..)
    , HoverKind(..)
    , LifeBlock
    , SplitResult(..)
    , combine
    , paths
    , singleton
    , splitAt
    , view
    )

import Common
import Creation.BeaconId as BeaconId exposing (DragBeaconId, DropBeaconId)
import Element exposing (..)
import Element.Border as Border
import Element.Input as Input
import LifeBlock.Validation as Validation
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


{-| Combines two lifeblocks in order, if possible.
-}
combine : LifeBlock -> LifeBlock -> Result (NonEmpty Validation.Error) LifeBlock
combine (LifeBlock first) (LifeBlock second) =
    case Validation.errors first second of
        [] ->
            Ok <| LifeBlock <| NonEmpty.append first second

        err :: moreErrs ->
            Err ( err, moreErrs )


type SplitResult a
    = Whole a
    | Split ( a, a )
    | BoundsError


{-| Splits a LifeBlock at the given index.
ie 0 would be taking the whole thing, while 'length' would be out of bounds.
-}
splitAt : Int -> LifeBlock -> SplitResult LifeBlock
splitAt index (LifeBlock lifepaths) =
    case Common.splitAt index lifepaths of
        Common.Split ( left, right ) ->
            Split ( LifeBlock left, LifeBlock right )

        Common.Whole whole ->
            Whole <| LifeBlock whole

        Common.None ->
            BoundsError


type alias ViewOptions msg =
    { baseAttrs : List (Attribute msg)
    , onDelete : Maybe msg
    , benchIndex : Int
    , hover : Hover
    }


type Hover
    = Warning
    | Before HoverKind
    | After HoverKind
    | None


type HoverKind
    = Success
    | Failure


view : ViewOptions msg -> LifeBlock -> Element msg
view opts (LifeBlock lifepaths) =
    let
        warnAttr : Maybe (Attribute msg)
        warnAttr =
            Validation.warnings lifepaths
                |> viewWarnings
                |> Maybe.map Element.onRight

        hoverAttr : Attribute msg
        hoverAttr =
            opts.benchIndex
                |> BeaconId.warningHoverId
                |> BeaconId.hoverAttribute

        exclamation =
            case ( warnAttr, opts.hover == Warning ) of
                ( Just attr, True ) ->
                    el [ attr, hoverAttr ] <| text "!"

                ( Just _, False ) ->
                    el [ hoverAttr ] <| text "!"

                ( Nothing, _ ) ->
                    none

        topRow : Element msg
        topRow =
            row [ width fill ] <|
                [ exclamation
                , Input.button
                    [ alignRight ]
                    { onPress = opts.onDelete
                    , label = text "X"
                    }
                ]

        withBeacon : Int -> Maybe DragBeaconId
        withBeacon blockIndex =
            Just <|
                BeaconId.benchDragId
                    { benchIndex = opts.benchIndex
                    , blockIndex = blockIndex
                    }

        middle : List (Element msg)
        middle =
            topRow
                :: List.indexedMap
                    (\blockIndex path -> Lifepath.view { withBeacon = withBeacon blockIndex } path)
                    (NonEmpty.toList lifepaths)

        dropZone : DropBeaconId -> Element msg
        dropZone id =
            let
                dropAttrs =
                    Border.width 1 :: opts.baseAttrs
            in
            el (BeaconId.dropAttribute id :: dropAttrs)
                (el [ centerX, centerY ] <| text "+")

        -- TODO drop highlight
        before =
            dropZone (BeaconId.beforeSlotDropId opts.benchIndex)

        after =
            dropZone (BeaconId.afterSlotDropId opts.benchIndex)
    in
    column opts.baseAttrs <|
        (before :: middle ++ [ after ])


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
