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
import Element.Font as Font
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
    , setFix : NonEmpty Validation.WarningReason -> msg
    }


type Hover
    = Warning Int
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

        ( before, after ) =
            case opts.hover of
                Carry (Just ( Before, True )) ->
                    ( dropZone <| Poised ( BeaconId.Before opts.benchIndex, Colors.successGlow )
                    , dropZone <| AwaitingCarry <| BeaconId.After opts.benchIndex
                    )

                Carry (Just ( Before, False )) ->
                    ( dropZone <| Poised ( BeaconId.Before opts.benchIndex, Colors.failureGlow )
                    , dropZone <| AwaitingCarry <| BeaconId.After opts.benchIndex
                    )

                Carry (Just ( After, True )) ->
                    ( dropZone <| AwaitingCarry <| BeaconId.Before opts.benchIndex
                    , dropZone <| Poised ( BeaconId.After opts.benchIndex, Colors.successGlow )
                    )

                Carry (Just ( After, False )) ->
                    ( dropZone <| AwaitingCarry <| BeaconId.Before opts.benchIndex
                    , dropZone <| Poised ( BeaconId.After opts.benchIndex, Colors.failureGlow )
                    )

                Carry Nothing ->
                    ( dropZone <| AwaitingCarry <| BeaconId.Before opts.benchIndex
                    , dropZone <| AwaitingCarry <| BeaconId.After opts.benchIndex
                    )

                FilterButton Before ->
                    ( if startsBorn lifeBlock then
                        dropZone <| AwaitingHover <| BeaconId.HoverBefore opts.benchIndex

                      else
                        dropZone <| Hovered ( BeaconId.HoverBefore opts.benchIndex, ( Before, lifeBlock ) )
                    , dropZone <| AwaitingHover <| BeaconId.HoverAfter opts.benchIndex
                    )

                FilterButton After ->
                    ( dropZone <| AwaitingHover <| BeaconId.HoverBefore opts.benchIndex
                    , dropZone <| Hovered ( BeaconId.HoverAfter opts.benchIndex, ( After, lifeBlock ) )
                    )

                _ ->
                    -- warning and none
                    ( dropZone <| AwaitingHover <| BeaconId.HoverBefore opts.benchIndex
                    , dropZone <| AwaitingHover <| BeaconId.HoverAfter opts.benchIndex
                    )
    in
    column opts.baseAttrs <|
        (before :: middle opts lifeBlock ++ [ after ])


startsBorn : LifeBlock -> Bool
startsBorn (LifeBlock ( first, _ )) =
    first.born


{-| The states of a dropzone above or below a lifeblock

TODO first two need better names

  - AwaitingHover - waiting to show filter button
  - AwaitingCarry - waiting to show success / failure highlight
  - Hovered - filter button
  - Poised - success / failure hightlight

-}
type DropZoneState msg
    = AwaitingHover BeaconId.HoverBeaconLocation
    | AwaitingCarry BeaconId.DropBeaconLocation
    | Hovered ( BeaconId.HoverBeaconLocation, Fit )
    | Poised ( BeaconId.DropBeaconLocation, Attribute msg )


type alias DropZoneOpts msg =
    { baseAttrs : List (Attribute msg)
    , state : DropZoneState msg
    , filterPressed : Fit -> msg
    }


viewDropZone : DropZoneOpts msg -> Element msg
viewDropZone { baseAttrs, state, filterPressed } =
    case state of
        AwaitingCarry location ->
            el ((BeaconId.attribute <| BeaconId.drop location) :: baseAttrs)
                (el [ centerX, centerY ] <| text "+")

        Poised ( location, highlight ) ->
            el ((BeaconId.attribute <| BeaconId.drop location) :: highlight :: baseAttrs)
                (el [ centerX, centerY ] <| text "+")

        AwaitingHover location ->
            el ((BeaconId.attribute <| BeaconId.hover location) :: baseAttrs)
                (el [ centerX, centerY ] <| text "+")

        Hovered ( location, fit ) ->
            el ((BeaconId.attribute <| BeaconId.hover location) :: baseAttrs) <|
                el [ centerX, centerY ] <|
                    Input.button []
                        { onPress = Just <| filterPressed fit
                        , label = text "filter"
                        }


middle : ViewOptions msg -> LifeBlock -> List (Element msg)
middle opts (LifeBlock lifepaths) =
    let
        topRow : Element msg
        topRow =
            row [ width fill ] <|
                [ maybeWarningsIcon opts lifepaths
                , Input.button
                    [ alignRight ]
                    { onPress = opts.onDelete
                    , label = text "X"
                    }
                ]

        withBeacon : Int -> Maybe BeaconId.DragBeaconLocation
        withBeacon blockIndex =
            Just <|
                BeaconId.Bench
                    { benchIndex = opts.benchIndex
                    , blockIndex = blockIndex
                    }
    in
    topRow
        :: List.indexedMap
            (\blockIndex path -> Lifepath.view (withBeacon blockIndex) path)
            (NonEmpty.toList lifepaths)


maybeWarningsIcon : ViewOptions msg -> NonEmpty Lifepath -> Element msg
maybeWarningsIcon opts lifepaths =
    lifepaths
        |> Validation.warnings
        |> NonEmpty.fromList
        |> Maybe.map (warningsIcons opts)
        |> Maybe.withDefault Element.none


warningsIcons : ViewOptions msg -> NonEmpty Validation.Warning -> Element msg
warningsIcons opts warnings =
    row [] <|
        List.map (singleWarningIcon opts warnings) <|
            List.range 0 (NonEmpty.length warnings - 1)


singleWarningIcon : ViewOptions msg -> NonEmpty Validation.Warning -> Int -> Element msg
singleWarningIcon opts warnings warningIndex =
    let
        hoverAttr : Attribute msg
        hoverAttr =
            BeaconId.LifeBlockWarning
                { benchIndex = opts.benchIndex
                , warningIndex = warningIndex
                }
                |> BeaconId.hover
                |> BeaconId.attribute

        tooltip : Element msg
        tooltip =
            let
                warns : NonEmpty (Element msg)
                warns =
                    NonEmpty.indexedMap
                        (\index item ->
                            if index == warningIndex then
                                viewHighlightedWarn item

                            else
                                viewWarn item
                        )
                        warnings
            in
            column [] <| NonEmpty.toList warns

        viewWarn (Validation.Warning { message }) =
            text message

        viewHighlightedWarn (Validation.Warning { message }) =
            el [ Font.color Colors.red ] <| text message

        attrs : List (Attribute msg)
        attrs =
            let
                position =
                    if opts.benchIndex < 3 then
                        Element.onRight

                    else
                        Element.onLeft
            in
            if opts.hover == Warning warningIndex then
                [ position tooltip, hoverAttr ]

            else
                [ hoverAttr ]

        warningReason (Validation.Warning { reason }) =
            reason

        onPress : Maybe msg
        onPress =
            warnings
                |> (\warns -> Maybe.map NonEmpty.head (NonEmpty.drop warningIndex warns))
                |> Maybe.map warningReason
                -- TODO with this change, setFix should take a single
                |> Maybe.map NonEmpty.singleton
                |> Maybe.map opts.setFix
    in
    Input.button attrs
        { onPress = onPress
        , label = text "!"
        }
