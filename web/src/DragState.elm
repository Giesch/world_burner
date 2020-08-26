port module DragState exposing
    ( DragData
    , DragState(..)
    , DraggedItem
    , IdDecoders
    , PoisedState
    , Transition(..)
    , subscriptions
    )

import Common
import Geom exposing (Box, Point)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (optional, required)


{-| The possible drag and hover states of the ui.

  - None - not dragging or hovering over anything
  - Hovered - not dragging, and hovering over something of interest
    eg a tooltip
  - Dragged - dragging an item, and not over a meaningful drop
  - Poised - dragging an item, and over a meaningful drop
    this includes error or warning states

The ids represent the location of the relevant beacons.
The cache is the carried item and relevant state for dropping it.

-}
type DragState dragId dropId hoverId cache
    = None
    | Hovered hoverId
    | Dragged ( DraggedItem dragId, cache )
    | Poised ( PoisedState dragId dropId, cache )


type alias DraggedItem dragId =
    { beaconId : dragId
    , cursorOnScreen : Point
    , cursorOnDraggable : Point
    }


type alias PoisedState dragId dropId =
    { draggedItem : DraggedItem dragId
    , hoveredDropBeacon : dropId
    }


{-| Transitions are the external message type

  - BeginHover - begins a non-dragging hover
  - EndHover - ends a non-dragging hover
  - PickUp - the beginning of a drag
  - LetGo - the end of a drag (when non-hovering)
  - Drop - the end of a drag (when hovering)
  - Carry - any movement when in either Dragged or Poised states
    this includes
      - moving from Dragged to Poised
      - moving from Poised to Dragged
      - moving the cursor within Dragged or Poised states
  - NoOp - this represents invalid transitions
    this would ideally be unnecessary, but we can't show the elm compiler that
    invalid transitions won't be sent by draggable.js

-}
type Transition dragId dropId hoverId cache
    = PickUp (DraggedItem dragId)
    | LetGo
    | Drop
    | Carry (DragState dragId dropId hoverId cache)
    | BeginHover hoverId
    | EndHover
    | NoOp


{-| Internal messages received from the port
See draggable.js
-}
type Msg dragId dropId hoverId
    = Start (DraggedItem dragId)
    | Move (DragData dropId)
    | Stop (DragData dropId)
    | Hover (DragData hoverId)
    | DecodeError String


type alias DragData dropId =
    { cursor : Point
    , beacons : List (BeaconBox dropId)
    }


type alias BeaconBox dropId =
    { beaconId : dropId
    , box : Box
    }



-- SUBSCRIPTIONS


port dragEvents : (Decode.Value -> msg) -> Sub msg


subscriptions :
    IdDecoders dragId dropId hoverId
    -> DragState dragId dropId hoverId cache
    -> Sub (Transition dragId dropId hoverId cache)
subscriptions idDecoders dragState =
    Sub.map (transitions dragState) <|
        Sub.batch [ dragEvents (decodeDragEvents idDecoders) ]



-- TRANSITIONS & MOVEMENT


{-| Converts port messages to drag state transitions
-}
transitions :
    DragState dragId dropId hoverId cache
    -> Msg dragId dropId hoverId
    -> Transition dragId dropId hoverId cache
transitions dragState beaconMsg =
    case ( dragState, beaconMsg ) of
        ( None, Hover data ) ->
            case boundingBeaconId data of
                Just id ->
                    BeginHover id

                Nothing ->
                    NoOp

        ( Hovered hovered, Hover data ) ->
            case boundingBeaconId data of
                Just id ->
                    if id == hovered then
                        NoOp

                    else
                        BeginHover id

                Nothing ->
                    EndHover

        ( Hovered _, Start draggedItem ) ->
            PickUp draggedItem

        ( Hovered _, _ ) ->
            -- these are error states
            EndHover

        ( None, Start draggedItem ) ->
            PickUp draggedItem

        ( None, _ ) ->
            NoOp

        ( Dragged pair, Move data ) ->
            Carry <| carryState data pair

        ( Dragged _, Stop _ ) ->
            LetGo

        ( Dragged _, _ ) ->
            NoOp

        ( Poised ( { draggedItem }, cache ), Move data ) ->
            Carry <| carryState data ( draggedItem, cache )

        ( Poised _, Stop _ ) ->
            Drop

        ( Poised _, _ ) ->
            NoOp


carryState :
    DragData dropId
    -> ( DraggedItem dragId, cache )
    -> DragState dragId dropId hoverId cache
carryState data ( draggedItem, cache ) =
    let
        move : DraggedItem dragId -> DraggedItem dragId
        move item =
            { item | cursorOnScreen = data.cursor }
    in
    case boundingBeaconId data of
        Nothing ->
            Dragged <| ( move draggedItem, cache )

        Just dropBeaconId ->
            Poised <| ( PoisedState (move draggedItem) dropBeaconId, cache )


boundingBeaconId : DragData id -> Maybe id
boundingBeaconId data =
    nearestBeacon data
        |> Common.keepIf (\beacon -> Geom.bounds beacon.box data.cursor)
        |> Maybe.map .beaconId


nearestBeacon : DragData id -> Maybe (BeaconBox id)
nearestBeacon { cursor, beacons } =
    let
        distanceFromCursor : BeaconBox id -> Float
        distanceFromCursor =
            .box >> Geom.center >> Geom.distance cursor
    in
    Common.minimumBy distanceFromCursor beacons



-- DECODERS


decodeDragEvents :
    IdDecoders dragId dropId hoverId
    -> Decode.Value
    -> Msg dragId dropId hoverId
decodeDragEvents idDecoders value =
    case Decode.decodeValue (msgDecoder idDecoders) value of
        Ok msg ->
            msg

        Err err ->
            let
                _ =
                    Debug.log "DragState decode error" errorMsg

                errorMsg =
                    Decode.errorToString err
            in
            DecodeError errorMsg


msgDecoder : IdDecoders dragId dropId hoverId -> Decode.Decoder (Msg dragId dropId hoverId)
msgDecoder idDecoders =
    Decode.succeed BeaconJson
        |> required "type" eventDecoder
        |> required "cursor" Geom.pointDecoder
        |> required "beacons" beaconsDecoder
        |> optional "startBeaconId" (Decode.map Just Decode.string) Nothing
        |> optional "cursorOnDraggable" (Decode.map Just Geom.pointDecoder) Nothing
        |> Decode.andThen (dragEvent idDecoders)


type alias BeaconJson =
    { eventType : EventType
    , cursor : Point
    , beacons : List ( Int, Box )
    , startBeaconId : Maybe String
    , cursorOnDraggable : Maybe Point
    }


type EventType
    = StartEvent
    | MoveEvent
    | StopEvent
    | HoverEvent


eventDecoder : Decode.Decoder EventType
eventDecoder =
    Decode.string
        |> Decode.andThen
            (\eventType ->
                case eventType of
                    "start" ->
                        Decode.succeed StartEvent

                    "move" ->
                        Decode.succeed MoveEvent

                    "stop" ->
                        Decode.succeed StopEvent

                    "hover" ->
                        Decode.succeed HoverEvent

                    _ ->
                        Decode.fail ("Unknown drag event type " ++ eventType)
            )


beaconsDecoder : Decode.Decoder (List ( Int, Box ))
beaconsDecoder =
    Decode.list <|
        Decode.map2 Tuple.pair
            (Decode.field "id" Decode.int)
            Geom.boxDecoder


type alias IdDecoders dragId dropId hoverId =
    { toDragId : Int -> dragId
    , toDropId : Int -> dropId
    , toHoverId : Int -> hoverId
    }


dragEvent :
    IdDecoders dragId dropId hoverId
    -> BeaconJson
    -> Decode.Decoder (Msg dragId dropId hoverId)
dragEvent { toDragId, toDropId, toHoverId } json =
    let
        dropData : DragData dropId
        dropData =
            dragData toDropId json
    in
    case json.eventType of
        HoverEvent ->
            Decode.succeed <| Hover <| dragData toHoverId json

        StartEvent ->
            startEvent toDragId json dropData.cursor

        MoveEvent ->
            Decode.succeed <| Move dropData

        StopEvent ->
            Decode.succeed <| Stop dropData


{-| Converts BeaconJson to DragData, including only beacons of the expected type.
-}
dragData : (Int -> id) -> BeaconJson -> DragData id
dragData toId json =
    let
        convert : ( Int, Box ) -> BeaconBox id
        convert ( beaconId, box ) =
            BeaconBox (toId beaconId) box
    in
    { cursor = json.cursor
    , beacons = List.map convert json.beacons
    }


startEvent :
    (Int -> dragId)
    -> BeaconJson
    -> Point
    -> Decode.Decoder (Msg dragId dropId hoverId)
startEvent toDragId { startBeaconId, cursorOnDraggable } cursor =
    let
        dragId : Maybe dragId
        dragId =
            startBeaconId
                |> Maybe.andThen String.toInt
                |> Maybe.map toDragId
    in
    case ( dragId, cursorOnDraggable ) of
        ( Just id, Just onDraggable ) ->
            Decode.succeed <| Start <| DraggedItem id cursor onDraggable

        _ ->
            Decode.fail "Received start event with no beacon id"
