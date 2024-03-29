module LifeBlock exposing
    ( Hover(..)
    , LifeBlock
    , SplitResult(..)
    , combine
    , paths
    , singleton
    , splitAt
    , view
    )

import Colors
import Common
import Creation.BeaconId as BeaconId exposing (DragBeaconId, DropBeaconId)
import Element exposing (..)
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


type SplitResult
    = Whole LifeBlock
    | Split ( LifeBlock, LifeBlock )
    | BoundsError


{-| Splits a LifeBlock at the given index.
ie 0 would be taking the whole thing, while 'length' would be out of bounds.
-}
splitAt : Int -> LifeBlock -> SplitResult
splitAt index (LifeBlock lifepaths) =
    case Common.splitAt index lifepaths of
        Just ( [], whole ) ->
            Whole <| LifeBlock whole

        Just ( leftFirst :: leftRest, right ) ->
            Split ( LifeBlock ( leftFirst, leftRest ), LifeBlock right )

        Nothing ->
            BoundsError


type alias ViewOptions msg =
    { baseAttrs : List (Attribute msg)
    , onDelete : Maybe msg
    , benchIndex : Int
    , hover : Hover
    }


type Hover
    = Warning
      -- Bool = success or failure
    | Before Bool
    | After Bool
    | None


view : ViewOptions msg -> LifeBlock -> Element msg
view opts lifeBlock =
    let
        ( before, after ) =
            case opts.hover of
                Before True ->
                    ( viewBefore <| Just Colors.successGlow, viewAfter Nothing )

                Before False ->
                    ( viewBefore <| Just Colors.failureGlow, viewAfter Nothing )

                After True ->
                    ( viewBefore Nothing, viewAfter <| Just Colors.successGlow )

                After False ->
                    ( viewBefore Nothing, viewAfter <| Just Colors.failureGlow )

                _ ->
                    ( viewBefore Nothing, viewAfter Nothing )

        viewBefore highlight =
            dropZone (BeaconId.beforeSlotDropId opts.benchIndex) highlight

        viewAfter highlight =
            dropZone (BeaconId.afterSlotDropId opts.benchIndex) highlight

        dropZone : DropBeaconId -> Maybe (Attribute msg) -> Element msg
        dropZone id highlight =
            let
                dropAttrs =
                    case highlight of
                        Just high ->
                            high :: opts.baseAttrs

                        Nothing ->
                            opts.baseAttrs
            in
            el (BeaconId.dropAttribute id :: dropAttrs)
                (el [ centerX, centerY ] <| text "+")
    in
    column opts.baseAttrs <|
        (before :: middle opts lifeBlock ++ [ after ])


middle : ViewOptions msg -> LifeBlock -> List (Element msg)
middle opts (LifeBlock lifepaths) =
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

        exclamation : Element msg
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
    in
    topRow
        :: List.indexedMap
            (\blockIndex path -> Lifepath.view { withBeacon = withBeacon blockIndex } path)
            (NonEmpty.toList lifepaths)


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
