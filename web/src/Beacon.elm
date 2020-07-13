port module Beacon exposing
    ( DragData
    , DragState(..)
    , DraggedItem
    , HoverState
    , Transition(..)
    , attribute
    , getDraggedItem
    , subscriptions
    )

import Common
import Element
import Geom exposing (Box, Point)
import Html.Attributes
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode
import Set exposing (Set)


type DragState dragId dropId
    = NotDragging
    | Dragging (DraggedItem dragId)
    | Hovering (HoverState dragId dropId)


{-| Transitions are the external message type

  - PickUp - the beginning of a drag
  - LetGo - the end of a drag (when non-hovering)
  - Drop - the end of a drag (when hovering)
  - DragMove - any movement when in either Dragging or Hovering states
    this includes
      - moving from Dragging to Hovering
      - moving from Hovering to Dragging
      - moving the cursor within Dragging or Hovering states
  - NoOp - this represents invalid transitions, is bad, and shoudn't exist

-}
type Transition dragId dropId
    = PickUp (DraggedItem dragId)
    | LetGo (DraggedItem dragId)
    | Drop (HoverState dragId dropId)
    | DragMove (DragState dragId dropId)
    | NoOp


type alias HoverState dragId dropId =
    { draggedItem : DraggedItem dragId
    , hoveredDropBeacon : dropId
    }


{-| Internal messages received from the port
-}
type Msg dragId dropId
    = Start (DraggedItem dragId)
    | Move (DragData dropId)
    | Stop (DragData dropId)
    | Error


type alias DraggedItem dragId =
    { beaconId : dragId
    , cursorOnScreen : Point
    , cursorOnDraggable : Point
    }


type alias DragData dropId =
    { cursor : Point
    , beacons : List (BeaconBox dropId)
    }


type alias BeaconBox dropId =
    { beaconId : dropId
    , box : Box
    }



-- SUBSCRIPTIONS & DECODERS


port dragEvents : (Decode.Value -> msg) -> Sub msg


subscriptions :
    (Int -> Maybe dragId)
    -> (Int -> Maybe dropId)
    -> DragState dragId dropId
    -> Sub (Transition dragId dropId)
subscriptions toDragId toDropId dragState =
    Sub.map (transitions toDragId toDropId dragState) <|
        Sub.batch [ dragEvents (decodeDragEvents toDragId toDropId) ]


{-| Translates move messages into Transitions
-}
transitions :
    (Int -> Maybe dragId)
    -> (Int -> Maybe dropId)
    -> DragState dragId dropId
    -> Msg dragId dropId
    -> Transition dragId dropId
transitions toDragId toDropId dragState beaconMsg =
    case ( dragState, beaconMsg ) of
        ( NotDragging, Start draggedItem ) ->
            PickUp draggedItem

        ( NotDragging, _ ) ->
            NoOp

        ( Dragging draggedItem, Move data ) ->
            dragMove data dragState

        ( Dragging draggedItem, Stop _ ) ->
            LetGo draggedItem

        ( Dragging draggedItem, _ ) ->
            NoOp

        ( Hovering state, Move data ) ->
            dragMove data dragState

        ( Hovering hoverState, Stop _ ) ->
            Drop hoverState

        ( Hovering hoverState, _ ) ->
            NoOp


decodeDragEvents : (Int -> Maybe dragId) -> (Int -> Maybe dropId) -> Decode.Value -> Msg dragId dropId
decodeDragEvents toDragId toDropId value =
    case Decode.decodeValue (msgDecoder toDragId toDropId) value of
        Ok msg ->
            msg

        Err err ->
            let
                oops =
                    Debug.log <| Decode.errorToString err
            in
            Error


msgDecoder : (Int -> Maybe dragId) -> (Int -> Maybe dropId) -> Decode.Decoder (Msg dragId dropId)
msgDecoder toDragId toDropId =
    Decode.succeed BeaconJson
        |> required "type" eventDecoder
        |> required "cursor" Geom.pointDecoder
        |> required "beacons" beaconsDecoder
        |> optional "startBeaconId" (Decode.map Just Decode.string) Nothing
        |> optional "cursorOnDraggable" (Decode.map Just Geom.pointDecoder) Nothing
        |> Decode.andThen (dragEvent toDragId toDropId)


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

                    _ ->
                        Decode.fail ("Unknown drag event type " ++ eventType)
            )


beaconsDecoder : Decode.Decoder (List ( Int, Box ))
beaconsDecoder =
    Decode.list
        (Decode.map2
            Tuple.pair
            (Decode.field "id" Decode.int)
            Geom.boxDecoder
        )


dragEvent : (Int -> Maybe dragId) -> (Int -> Maybe dropId) -> BeaconJson -> Decode.Decoder (Msg dragId dropId)
dragEvent toDragId toDropId json =
    let
        data : DragData dropId
        data =
            dragData toDropId json
    in
    case json.eventType of
        StartEvent ->
            startEvent toDragId json data.cursor

        MoveEvent ->
            Decode.succeed <| Move data

        StopEvent ->
            Decode.succeed <| Stop data


dragData : (Int -> Maybe dropId) -> BeaconJson -> DragData dropId
dragData toDropId json =
    let
        convert : ( Int, Box ) -> Maybe (BeaconBox dropId)
        convert ( beaconId, box ) =
            case toDropId beaconId of
                Just dropId ->
                    Just <| BeaconBox dropId box

                Nothing ->
                    Nothing
    in
    { cursor = json.cursor
    , beacons = List.filterMap convert json.beacons
    }


startEvent : (Int -> Maybe dragId) -> BeaconJson -> Point -> Decode.Decoder (Msg dragId dropId)
startEvent toDragId { startBeaconId, cursorOnDraggable } cursor =
    let
        dragId : Maybe dragId
        dragId =
            startBeaconId
                |> Maybe.andThen String.toInt
                |> Maybe.andThen toDragId
    in
    case ( dragId, cursorOnDraggable ) of
        ( Just id, Just onDraggable ) ->
            Decode.succeed <| Start <| DraggedItem id cursor onDraggable

        _ ->
            Decode.fail "Received start event with no beacon id"



-- MOVEMENT


dragMove : DragData dropId -> DragState dragId dropId -> Transition dragId dropId
dragMove data dragState =
    let
        move : DraggedItem dragId -> DraggedItem dragId
        move draggedItem =
            { draggedItem | cursorOnScreen = data.cursor }
    in
    DragMove <|
        case
            ( getDraggedItem dragState
            , nearestBeaconId data
            )
        of
            ( Nothing, _ ) ->
                dragState

            ( Just draggedItem, Nothing ) ->
                Dragging <| move draggedItem

            ( Just draggedItem, Just dropBeaconId ) ->
                Hovering <| HoverState (move draggedItem) dropBeaconId


getDraggedItem : DragState dragId dropId -> Maybe (DraggedItem dragId)
getDraggedItem dragState =
    case dragState of
        NotDragging ->
            Nothing

        Dragging draggedItem ->
            Just draggedItem

        Hovering { draggedItem } ->
            Just draggedItem


nearestBeaconId : DragData dropId -> Maybe dropId
nearestBeaconId data =
    -- TODO use a range instead of bound
    nearestBeacon data
        |> Common.keepIf (\beacon -> Geom.bounds beacon.box data.cursor)
        |> Maybe.map .beaconId


nearestBeacon : DragData dropId -> Maybe (BeaconBox dropId)
nearestBeacon { cursor, beacons } =
    let
        distanceFromCursor : BeaconBox dropId -> Float
        distanceFromCursor =
            .box >> Geom.center >> Geom.distance cursor
    in
    Common.minimumBy distanceFromCursor beacons


attribute : Int -> Element.Attribute msg
attribute beaconId =
    Element.htmlAttribute <|
        Html.Attributes.attribute "data-beacon"
            (Encode.encode 0 <| Encode.int beaconId)
