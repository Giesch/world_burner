module Creation.Workbench exposing
    ( DropError(..)
    , Hover(..)
    , PickupError(..)
    , Workbench
    , WorkbenchOptions
    , default
    , deleteBlock
    , drop
    , pickup
    , view
    , viewDraggedBlock
    )

import Array exposing (Array)
import Colors
import Common
import Creation.BeaconId as BeaconId
    exposing
        ( BenchIndex
        , BenchLocation
        , DropBeaconLocation
        , HoverBeaconLocation
        )
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html
import Html.Attributes
import LifeBlock exposing (LifeBlock, SplitResult(..))
import LifeBlock.Validation as Validation
import Lifepath
import List.NonEmpty as NonEmpty exposing (NonEmpty)


type Workbench
    = Workbench (Array (Maybe LifeBlock))


default : Workbench
default =
    Workbench <| Array.repeat 4 Nothing


deleteBlock : Workbench -> BenchIndex -> Workbench
deleteBlock (Workbench bench) benchIndex =
    putBenchBlock benchIndex Nothing bench


type PickupError
    = PickupBoundsError
    | NoLifeBlock


pickup : Workbench -> BenchLocation -> Result PickupError ( Workbench, LifeBlock )
pickup (Workbench bench) { benchIndex, blockIndex } =
    case getBenchBlock benchIndex bench of
        OutOfBounds ->
            Err PickupBoundsError

        GotNothing ->
            Err NoLifeBlock

        GotBlock block ->
            case LifeBlock.splitAt blockIndex block of
                Whole pickedup ->
                    Ok ( putBenchBlock benchIndex Nothing bench, pickedup )

                Split ( left, right ) ->
                    Ok ( putBenchBlock benchIndex (Just left) bench, right )

                BoundsError ->
                    Err PickupBoundsError


dropBenchIndex : DropBeaconLocation -> BenchIndex
dropBenchIndex location =
    case location of
        BeaconId.Open loc ->
            loc

        BeaconId.Before loc ->
            loc

        BeaconId.After loc ->
            loc


type DropError
    = DropBoundsError
    | InvalidDropLocation
    | CombinationError (NonEmpty Validation.Error)


drop : Workbench -> LifeBlock -> DropBeaconLocation -> Result DropError Workbench
drop (Workbench bench) droppedBlock location =
    let
        benchIndex =
            dropBenchIndex location

        dropFinal : LifeBlock -> Result DropError Workbench
        dropFinal finalBlock =
            Ok <| putBenchBlock benchIndex (Just finalBlock) bench

        combineAndDrop :
            (LifeBlock -> Result (NonEmpty Validation.Error) LifeBlock)
            -> Result DropError Workbench
        combineAndDrop combineWithBenchBlock =
            case getBenchBlock benchIndex bench of
                OutOfBounds ->
                    Err DropBoundsError

                GotNothing ->
                    Err InvalidDropLocation

                GotBlock benchBlock ->
                    case combineWithBenchBlock benchBlock of
                        Ok combined ->
                            dropFinal combined

                        Err err ->
                            Err <| CombinationError err
    in
    case location of
        BeaconId.Open _ ->
            dropFinal droppedBlock

        BeaconId.Before _ ->
            combineAndDrop <| \benchBlock -> LifeBlock.combine droppedBlock benchBlock

        BeaconId.After _ ->
            combineAndDrop <| \benchBlock -> LifeBlock.combine benchBlock droppedBlock


type GetResult
    = OutOfBounds
    | GotNothing
    | GotBlock LifeBlock


getBenchBlock : BenchIndex -> Array (Maybe LifeBlock) -> GetResult
getBenchBlock index bench =
    case Array.get index bench of
        Nothing ->
            OutOfBounds

        Just Nothing ->
            GotNothing

        Just (Just block) ->
            GotBlock block


putBenchBlock : BenchIndex -> Maybe LifeBlock -> Array (Maybe LifeBlock) -> Workbench
putBenchBlock index maybeBlock bench =
    Workbench <| Array.set index maybeBlock bench


type Hover
    = Full FullHover
    | Empty HoverBeaconLocation
    | None


type alias FullHover =
    { hoveringBlock : LifeBlock
    , dropLocation : DropBeaconLocation
    , dropHighlight : Maybe Bool
    }


convertHighlight : Int -> FullHover -> LifeBlock.Hover
convertHighlight benchIndex { dropLocation, dropHighlight } =
    let
        showHighlight i hov =
            if i == benchIndex then
                hov

            else
                LifeBlock.None
    in
    case ( dropLocation, dropHighlight ) of
        ( BeaconId.Before i, Just True ) ->
            showHighlight i <| LifeBlock.Before True

        ( BeaconId.Before i, Just False ) ->
            showHighlight i <| LifeBlock.Before False

        ( BeaconId.After i, Just True ) ->
            showHighlight i <| LifeBlock.After True

        ( BeaconId.After i, Just False ) ->
            showHighlight i <| LifeBlock.After False

        _ ->
            LifeBlock.None


type alias WorkbenchOptions msg =
    { hover : Hover
    , deleteBenchBlock : BenchIndex -> msg
    }


view : Workbench -> WorkbenchOptions msg -> Element msg
view (Workbench slots) opts =
    let
        blockHover : Int -> LifeBlock.Hover
        blockHover benchIndex =
            case opts.hover of
                Empty (BeaconId.LifeBlockWarning i) ->
                    if i == benchIndex then
                        LifeBlock.Warning

                    else
                        LifeBlock.None

                Full full ->
                    convertHighlight benchIndex full

                None ->
                    LifeBlock.None

        viewBlock : Int -> LifeBlock -> Element msg
        viewBlock benchIndex =
            viewLifeBlock
                { benchIndex = benchIndex
                , deleteBenchBlock = opts.deleteBenchBlock
                , hover = blockHover benchIndex
                }

        viewSlot : Int -> Maybe LifeBlock -> Element msg
        viewSlot benchIndex block =
            block
                |> Maybe.map (viewBlock benchIndex)
                |> Maybe.withDefault (openSlot benchIndex opts)
    in
    row
        [ spacing 20
        , padding 40
        , centerX
        , centerY
        , height <| px 500
        , width fill
        ]
        (Array.toList <| Array.indexedMap viewSlot slots)


openSlot : Int -> WorkbenchOptions msg -> Element msg
openSlot benchIndex { hover } =
    let
        beingHovered =
            case hover of
                Full full ->
                    full.dropLocation == BeaconId.Open benchIndex

                _ ->
                    False
    in
    if beingHovered then
        el
            (BeaconId.dropAttribute (BeaconId.openSlotDropId benchIndex)
                :: Colors.successGlow
                :: slotAttrs
            )
            (el [ centerX, centerY ] <| text "+")

    else
        el
            (BeaconId.dropAttribute (BeaconId.openSlotDropId benchIndex)
                :: Border.width 1
                :: slotAttrs
            )
            (el [ centerX, centerY ] <| text "+")


type alias DraggedBlockOptions =
    { top : Float
    , left : Float
    , errors : Maybe (NonEmpty Validation.Error)
    }


{-| Displays the hovering block at the users cursor
-}
viewDraggedBlock : LifeBlock -> DraggedBlockOptions -> Element msg
viewDraggedBlock lifeBlock { top, left, errors } =
    let
        position : String -> Float -> Html.Attribute msg
        position name px =
            Html.Attributes.style name <| String.fromFloat px ++ "px"

        errsAttr : Attribute msg
        errsAttr =
            Maybe.map viewErrors errors
                |> Maybe.withDefault none
                |> Element.onLeft
    in
    column
        ([ htmlAttribute <| Html.Attributes.style "position" "fixed"
         , htmlAttribute <| position "top" top
         , htmlAttribute <| position "left" left
         , htmlAttribute <| Html.Attributes.style "list-style" "none"
         , htmlAttribute <| Html.Attributes.style "padding" "0"
         , htmlAttribute <| Html.Attributes.style "margin" "0"
         , width Lifepath.lifepathWidth
         , errsAttr
         , spacing 20
         , padding 12
         ]
            ++ Common.userSelectNone
        )
        (List.map
            (Lifepath.view { withBeacon = Nothing })
            (NonEmpty.toList <| LifeBlock.paths lifeBlock)
        )


viewErrors : NonEmpty Validation.Error -> Element msg
viewErrors errs =
    let
        viewErr (Validation.Error msg) =
            text msg
    in
    column [] <| List.map viewErr <| NonEmpty.toList errs


type alias LifeBlockOptions msg =
    { benchIndex : Int
    , deleteBenchBlock : BenchIndex -> msg
    , hover : LifeBlock.Hover
    }


viewLifeBlock : LifeBlockOptions msg -> LifeBlock -> Element msg
viewLifeBlock opts =
    LifeBlock.view
        { baseAttrs = slotAttrs
        , onDelete = Just <| opts.deleteBenchBlock opts.benchIndex
        , benchIndex = opts.benchIndex
        , hover = opts.hover
        }


{-| Attributes common to open and filled slots on the bench
-}
slotAttrs : List (Attribute msg)
slotAttrs =
    [ Background.color Colors.white
    , Font.color Colors.black
    , Border.rounded 8
    , Border.color Colors.darkened
    , width <| px 350
    , height fill
    , spacing 20
    , padding 12
    , centerX
    , centerY
    ]
