port module Beacons exposing
    ( DragData
    , DraggedItem
    , Msg(..)
    , subscriptions
    )

import Geom exposing (Box, Point)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (optional, required)


type Msg
    = Start DraggedItem
    | Move DragData
    | Stop DragData
    | NoOp


type alias DraggedItem =
    { beaconId : Int
    , cursorOnScreen : Point
    , cursorOnDraggable : Point
    }


port dragEvents : (Decode.Value -> msg) -> Sub msg


subscriptions : Sub Msg
subscriptions =
    Sub.batch [ dragEvents decodeDragEvents ]


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
            NoOp


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


startEvent : BeaconJson -> Point -> Decode.Decoder Msg
startEvent { startBeaconId, cursorOnDraggable } cursor =
    case ( Maybe.andThen String.toInt startBeaconId, cursorOnDraggable ) of
        ( Just id, Just onDraggable ) ->
            Decode.succeed <| Start <| DraggedItem id cursor onDraggable

        _ ->
            Decode.fail "Recieved start event with no beacon id"


type alias DragData =
    { cursor : Point
    , beacons : List BeaconBox
    }


type alias BeaconBox =
    { beaconId : Int
    , box : Box
    }


dragData : BeaconJson -> DragData
dragData json =
    { cursor = json.cursor
    , beacons =
        List.map
            (\( beaconId, box ) -> BeaconBox beaconId box)
            json.beacons
    }
