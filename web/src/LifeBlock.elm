module LifeBlock exposing
    ( Fit
    , Hover(..)
    , LifeBlock
    , Position(..)
    , SplitResult(..)
    , combine
    , paths
    , singleton
    , splitAt
    , view
    )

import Colors
import Common
import Creation.BeaconId as BeaconId exposing (DragBeaconId, DropBeaconId, HoverBeaconId)
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
    , filterPressed : Fit -> msg
    }


type Hover
    = Warning
    | FilterButton Position
      -- Bool = success or failure
    | Carry (Maybe ( Position, Bool ))
    | None


type Position
    = Before
    | After


type alias Fit =
    ( Position, LifeBlock )


view : ViewOptions msg -> LifeBlock -> Element msg
view opts lifeBlock =
    let
        dropZone state =
            viewDropZone
                { baseAttrs = opts.baseAttrs
                , filterPressed = opts.filterPressed
                , state = state
                }

        beforeSlotDropId =
            BeaconId.beforeSlotDropId opts.benchIndex

        afterSlotDropId =
            BeaconId.afterSlotDropId opts.benchIndex

        beforeSlotHoverId =
            BeaconId.beforeSlotHoverId opts.benchIndex

        afterSlotHoverId =
            BeaconId.afterSlotHoverId opts.benchIndex

        ( before, after ) =
            case opts.hover of
                Carry (Just ( Before, True )) ->
                    ( dropZone <| CarriedOver ( beforeSlotDropId, Colors.successGlow )
                    , dropZone <| AwaitingCarry afterSlotDropId
                    )

                Carry (Just ( Before, False )) ->
                    ( dropZone <| CarriedOver ( beforeSlotDropId, Colors.failureGlow )
                    , dropZone <| AwaitingCarry afterSlotDropId
                    )

                Carry (Just ( After, True )) ->
                    ( dropZone <| AwaitingCarry beforeSlotDropId
                    , dropZone <| CarriedOver ( afterSlotDropId, Colors.successGlow )
                    )

                Carry (Just ( After, False )) ->
                    ( dropZone <| AwaitingCarry beforeSlotDropId
                    , dropZone <| CarriedOver ( afterSlotDropId, Colors.failureGlow )
                    )

                Carry Nothing ->
                    ( dropZone <| AwaitingCarry beforeSlotDropId
                    , dropZone <| AwaitingCarry afterSlotDropId
                    )

                FilterButton Before ->
                    ( if startsBorn lifeBlock then
                        dropZone <| AwaitingHover beforeSlotHoverId

                      else
                        dropZone <| HoveredOver ( beforeSlotHoverId, ( Before, lifeBlock ) )
                    , dropZone <| AwaitingHover afterSlotHoverId
                    )

                FilterButton After ->
                    ( dropZone <| AwaitingHover beforeSlotHoverId
                    , dropZone <| HoveredOver ( afterSlotHoverId, ( After, lifeBlock ) )
                    )

                _ ->
                    -- warning and none
                    ( dropZone <| AwaitingHover <| beforeSlotHoverId
                    , dropZone <| AwaitingHover <| afterSlotHoverId
                    )
    in
    column opts.baseAttrs <|
        (before :: middle opts lifeBlock ++ [ after ])


startsBorn : LifeBlock -> Bool
startsBorn (LifeBlock ( first, _ )) =
    first.born


{-| The states of a dropzone above or below a lifeblock

  - AwaitingHover - a plus sign waiting to show filter button
  - AwaitingCarry - a plus sign waiting to show success / failure highlight
  - HoveredOver - filter button
  - CarriedOver - success / failure hightlight

-}
type DropZoneState msg
    = AwaitingHover HoverBeaconId
    | AwaitingCarry DropBeaconId
    | HoveredOver ( HoverBeaconId, Fit )
    | CarriedOver ( DropBeaconId, Attribute msg )


type alias DropZoneOpts msg =
    { baseAttrs : List (Attribute msg)
    , state : DropZoneState msg
    , filterPressed : Fit -> msg
    }


viewDropZone : DropZoneOpts msg -> Element msg
viewDropZone { baseAttrs, state, filterPressed } =
    case state of
        AwaitingCarry dropBeaconId ->
            el (BeaconId.dropAttribute dropBeaconId :: baseAttrs)
                (el [ centerX, centerY ] <| text "+")

        CarriedOver ( dropBeaconId, highlight ) ->
            el (BeaconId.dropAttribute dropBeaconId :: highlight :: baseAttrs)
                (el [ centerX, centerY ] <| text "+")

        AwaitingHover hoverBeaconId ->
            el (BeaconId.hoverAttribute hoverBeaconId :: baseAttrs)
                (el [ centerX, centerY ] <| text "+")

        HoveredOver ( hoverBeaconId, fit ) ->
            el (BeaconId.hoverAttribute hoverBeaconId :: baseAttrs)
                (el [ centerX, centerY ] <|
                    Input.button []
                        { onPress = Just <| filterPressed fit
                        , label = text "filter"
                        }
                )


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
