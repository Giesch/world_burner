port module Beacons exposing
    ( DragData
    , DragState(..)
    , DraggedItem
    ,  HoverState
       -- TODO remove the (..) from Msg

    , Transition(..)
    , getDraggedItem
    , subscriptions
    )

import Common
import Geom exposing (Box, Point)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (optional, required)
import Set exposing (Set)


type DragState
    = NotDragging
    | Dragging DraggedItem
    | Hovering HoverState


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
type Transition
    = PickUp DraggedItem
    | LetGo DraggedItem
    | Drop HoverState
    | DragMove DragState
    | NoOp


type alias HoverState =
    { draggedItem : DraggedItem
    , hoveredDropBeacon : Int
    }


{-| Internal messages received from the port
-}
type Msg
    = Start DraggedItem
    | Move DragData
    | Stop DragData
    | Error


type alias DraggedItem =
    { beaconId : Int
    , cursorOnScreen : Point
    , cursorOnDraggable : Point
    }


type alias DragData =
    { cursor : Point
    , beacons : List BeaconBox
    }


type alias BeaconBox =
    { beaconId : Int
    , box : Box
    }



-- SUBSCRIPTIONS & DECODERS


port dragEvents : (Decode.Value -> msg) -> Sub msg


subscriptions : Set Int -> DragState -> Sub Transition
subscriptions dropBeaconIds dragState =
    Sub.map (transitions dropBeaconIds dragState) <|
        Sub.batch [ dragEvents decodeDragEvents ]


transitions : Set Int -> DragState -> Msg -> Transition
transitions dropBeaconIds dragState beaconMsg =
    case ( dragState, beaconMsg ) of
        ( NotDragging, Start draggedItem ) ->
            PickUp draggedItem

        ( NotDragging, _ ) ->
            NoOp

        ( Dragging draggedItem, Move data ) ->
            dragMove dropBeaconIds data dragState

        ( Dragging draggedItem, Stop _ ) ->
            LetGo draggedItem

        ( Dragging draggedItem, _ ) ->
            NoOp

        ( Hovering state, Move data ) ->
            dragMove dropBeaconIds data dragState

        ( Hovering hoverState, Stop _ ) ->
            Drop hoverState

        ( Hovering hoverState, _ ) ->
            NoOp


decodeDragEvents : Decode.Value -> Msg
decodeDragEvents value =
    case Decode.decodeValue msgDecoder value of
        Ok msg ->
            msg

        Err err ->
            let
                oops =
                    Debug.log <| Decode.errorToString err
            in
            Error


msgDecoder : Decode.Decoder Msg
msgDecoder =
    Decode.succeed BeaconJson
        |> required "type" eventDecoder
        |> required "cursor" Geom.pointDecoder
        |> required "beacons" beaconsDecoder
        |> optional "startBeaconId" (Decode.map Just Decode.string) Nothing
        |> optional "cursorOnDraggable" (Decode.map Just Geom.pointDecoder) Nothing
        |> Decode.andThen dragEvent


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


dragEvent : BeaconJson -> Decode.Decoder Msg
dragEvent json =
    let
        data : DragData
        data =
            dragData json
    in
    case json.eventType of
        StartEvent ->
            startEvent json data.cursor

        MoveEvent ->
            Decode.succeed <| Move data

        StopEvent ->
            Decode.succeed <| Stop data


dragData : BeaconJson -> DragData
dragData json =
    { cursor = json.cursor
    , beacons =
        List.map
            (\( beaconId, box ) -> BeaconBox beaconId box)
            json.beacons
    }


startEvent : BeaconJson -> Point -> Decode.Decoder Msg
startEvent { startBeaconId, cursorOnDraggable } cursor =
    case ( Maybe.andThen String.toInt startBeaconId, cursorOnDraggable ) of
        ( Just id, Just onDraggable ) ->
            Decode.succeed <| Start <| DraggedItem id cursor onDraggable

        _ ->
            Decode.fail "Received start event with no beacon id"



-- MOVEMENT


dragMove : Set Int -> DragData -> DragState -> Transition
dragMove dropBeaconIds data dragState =
    let
        move : DraggedItem -> DraggedItem
        move draggedItem =
            { draggedItem | cursorOnScreen = data.cursor }
    in
    DragMove <|
        case
            ( getDraggedItem dragState
            , nearestBeaconId dropBeaconIds data
            )
        of
            ( Nothing, _ ) ->
                dragState

            ( Just draggedItem, Nothing ) ->
                Dragging <| move draggedItem

            ( Just draggedItem, Just dropBeaconId ) ->
                Hovering <| HoverState (move draggedItem) dropBeaconId


getDraggedItem : DragState -> Maybe DraggedItem
getDraggedItem dragState =
    case dragState of
        NotDragging ->
            Nothing

        Dragging draggedItem ->
            Just draggedItem

        Hovering { draggedItem } ->
            Just draggedItem


nearestBeaconId : Set Int -> DragData -> Maybe Int
nearestBeaconId beaconIds data =
    -- TODO use a range instead of bound
    nearestBeacon beaconIds data
        |> Common.keepIf (\beacon -> Geom.bounds beacon.box data.cursor)
        |> Maybe.map .beaconId


nearestBeacon : Set Int -> DragData -> Maybe BeaconBox
nearestBeacon beaconIds { cursor, beacons } =
    let
        keep : BeaconBox -> Bool
        keep beacon =
            Set.member beacon.beaconId beaconIds

        distanceFromCursor : BeaconBox -> Float
        distanceFromCursor =
            .box >> Geom.center >> Geom.distance cursor
    in
    beacons
        |> List.filter keep
        |> Common.minimumBy distanceFromCursor
