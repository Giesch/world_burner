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
        , DropBeaconId
        , DropBeaconLocation
        , HoverBeaconId
        , HoverBeaconLocation
        )
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html
import Html.Attributes
import LifeBlock exposing (LifeBlock, SplitResult(..))
import Lifepath
import List.NonEmpty as NonEmpty


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
            case LifeBlock.splitAt block blockIndex of
                Whole pickedup ->
                    Ok ( putBenchBlock benchIndex Nothing bench, pickedup )

                Split ( left, right ) ->
                    Ok ( putBenchBlock benchIndex (Just left) bench, right )

                NotFound ->
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
    | CombinationError String


drop : Workbench -> LifeBlock -> DropBeaconLocation -> Result DropError Workbench
drop (Workbench bench) droppedBlock location =
    let
        benchIndex =
            dropBenchIndex location

        dropFinal : LifeBlock -> Result DropError Workbench
        dropFinal finalBlock =
            Ok <| putBenchBlock benchIndex (Just finalBlock) bench

        combineAndDrop :
            (LifeBlock -> Result String LifeBlock)
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
    }


type alias WorkbenchOptions msg =
    { hover : Hover
    , deleteBenchBlock : BenchIndex -> msg
    }


view : Workbench -> WorkbenchOptions msg -> Element msg
view (Workbench slots) opts =
    let
        warningHovered : Int -> Bool
        warningHovered benchIndex =
            case opts.hover of
                Empty (BeaconId.LifeBlockWarning i) ->
                    i == benchIndex

                _ ->
                    False

        viewBlock : Int -> LifeBlock -> Element msg
        viewBlock benchIndex =
            viewLifeBlock
                { benchIndex = benchIndex
                , deleteBenchBlock = opts.deleteBenchBlock
                , dropBeaconOverride = Nothing
                , warningHovered = warningHovered benchIndex
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
openSlot benchIndex { hover, deleteBenchBlock } =
    let
        hoveringBlock : Maybe LifeBlock
        hoveringBlock =
            case hover of
                Full full ->
                    if full.dropLocation == BeaconId.Open benchIndex then
                        Just full.hoveringBlock

                    else
                        Nothing

                _ ->
                    Nothing
    in
    case hoveringBlock of
        Just block ->
            viewLifeBlock
                { benchIndex = benchIndex
                , deleteBenchBlock = deleteBenchBlock
                , dropBeaconOverride =
                    Just <| BeaconId.openSlotDropId benchIndex
                , warningHovered = False
                }
                block

        _ ->
            el
                (BeaconId.dropAttribute (BeaconId.openSlotDropId benchIndex)
                    :: Border.width 1
                    :: slotAttrs
                )
                (el [ centerX, centerY ] <| text "+")


{-| Displays the hovering block at the users cursor
-}
viewDraggedBlock : LifeBlock -> { top : Float, left : Float } -> Element msg
viewDraggedBlock lifeBlock { top, left } =
    let
        position : String -> Float -> Html.Attribute msg
        position name px =
            Html.Attributes.style name <| String.fromFloat px ++ "px"
    in
    column
        ([ htmlAttribute <| Html.Attributes.style "position" "fixed"
         , htmlAttribute <| position "top" top
         , htmlAttribute <| position "left" left
         , htmlAttribute <| Html.Attributes.style "list-style" "none"
         , htmlAttribute <| Html.Attributes.style "padding" "0"
         , htmlAttribute <| Html.Attributes.style "margin" "0"
         , width Lifepath.lifepathWidth
         , spacing 20
         , padding 12
         ]
            ++ Common.userSelectNone
        )
        (List.map
            (Lifepath.view { withBeacon = Nothing })
            (NonEmpty.toList <| LifeBlock.paths lifeBlock)
        )


type alias LifeBlockOptions msg =
    { benchIndex : Int
    , deleteBenchBlock : BenchIndex -> msg
    , dropBeaconOverride : Maybe DropBeaconId
    , warningHovered : Bool
    }


viewLifeBlock : LifeBlockOptions msg -> LifeBlock -> Element msg
viewLifeBlock { benchIndex, deleteBenchBlock, dropBeaconOverride, warningHovered } block =
    LifeBlock.view
        { baseAttrs = slotAttrs
        , dropBeaconOverride = dropBeaconOverride
        , onDelete = Just <| deleteBenchBlock benchIndex
        , benchIndex = benchIndex
        , warningHovered = warningHovered
        }
        block


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
