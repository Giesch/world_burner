port module DragState exposing
    ( DragData
    , DragState(..)
    , DraggedItem
    , HoverState
    , Transition(..)
    , attribute
    , subscriptions
    )

import Common
import Element
import Geom exposing (Box, Point)
import Html.Attributes
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode


type DragState dragId dropId hoverId cache
    = None
    | Dragging ( DraggedItem dragId, cache )
    | Hovering ( HoverState dragId dropId, cache )
    | EmptyHover hoverId


{-| Transitions are the external message type

  - PickUp - the beginning of a drag
  - LetGo - the end of a drag (when non-hovering)
  - Drop - the end of a drag (when hovering)
  - DragMove - any movement when in either Dragging or Hovering states
    this includes
      - moving from Dragging to Hovering
      - moving from Hovering to Dragging
      - moving the cursor within Dragging or Hovering states
  - Hover - TODO write me
  - NoOp - this represents invalid transitions, is bad, and shoudn't exist

-}
type Transition dragId dropId hoverId cache
    = PickUp (DraggedItem dragId)
    | LetGo
    | Drop
    | DragMove (DragState dragId dropId hoverId cache)
    | BeginHover hoverId
    | EndHover
    | NoOp


type alias HoverState dragId dropId =
    { draggedItem : DraggedItem dragId
    , hoveredDropBeacon : dropId
    }


{-| Internal messages received from the port
-}
type Msg dragId dropId hoverId
    = Start (DraggedItem dragId)
      -- TODO rename DragMove
    | Move (DragData dropId)
    | Stop (DragData dropId)
    | Hover (DragData hoverId)
    | Error Decode.Error


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
    -> (Int -> Maybe hoverId)
    -> DragState dragId dropId hoverId cache
    -> Sub (Transition dragId dropId hoverId cache)
subscriptions toDragId toDropId toHoverId dragState =
    Sub.map (transitions dragState) <|
        Sub.batch [ dragEvents (decodeDragEvents toDragId toDropId toHoverId) ]


{-| Translates move messages into Transitions
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

        ( EmptyHover hovered, Hover data ) ->
            case boundingBeaconId data of
                Just id ->
                    if id == hovered then
                        NoOp

                    else
                        BeginHover id

                Nothing ->
                    EndHover

        ( EmptyHover _, Start draggedItem ) ->
            PickUp draggedItem

        ( EmptyHover _, _ ) ->
            -- these are error states
            EndHover

        ( None, Start draggedItem ) ->
            PickUp draggedItem

        ( None, _ ) ->
            NoOp

        ( Dragging pair, Move data ) ->
            dragMove data pair

        ( Dragging _, Stop _ ) ->
            LetGo

        ( Dragging _, _ ) ->
            NoOp

        ( Hovering ( { draggedItem }, cache ), Move data ) ->
            dragMove data ( draggedItem, cache )

        ( Hovering _, Stop _ ) ->
            Drop

        ( Hovering _, _ ) ->
            NoOp


decodeDragEvents :
    (Int -> Maybe dragId)
    -> (Int -> Maybe dropId)
    -> (Int -> Maybe hoverId)
    -> Decode.Value
    -> Msg dragId dropId hoverId
decodeDragEvents toDragId toDropId toHoverId value =
    case Decode.decodeValue (msgDecoder toDragId toDropId toHoverId) value of
        Ok msg ->
            msg

        Err err ->
            let
                _ =
                    Debug.log <| Decode.errorToString err
            in
            Error err


msgDecoder :
    (Int -> Maybe dragId)
    -> (Int -> Maybe dropId)
    -> (Int -> Maybe hoverId)
    -> Decode.Decoder (Msg dragId dropId hoverId)
msgDecoder toDragId toDropId toHoverId =
    Decode.succeed BeaconJson
        |> required "type" eventDecoder
        |> required "cursor" Geom.pointDecoder
        |> required "beacons" beaconsDecoder
        |> optional "startBeaconId" (Decode.map Just Decode.string) Nothing
        |> optional "cursorOnDraggable" (Decode.map Just Geom.pointDecoder) Nothing
        |> Decode.andThen (dragEvent toDragId toDropId toHoverId)


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
    Decode.list
        (Decode.map2
            Tuple.pair
            (Decode.field "id" Decode.int)
            Geom.boxDecoder
        )



-- TODO take the int decoders as named args


dragEvent :
    (Int -> Maybe dragId)
    -> (Int -> Maybe dropId)
    -> (Int -> Maybe hoverId)
    -> BeaconJson
    -> Decode.Decoder (Msg dragId dropId hoverId)
dragEvent toDragId toDropId toHoverId json =
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
dragData : (Int -> Maybe id) -> BeaconJson -> DragData id
dragData toId json =
    let
        convert : ( Int, Box ) -> Maybe (BeaconBox id)
        convert ( beaconId, box ) =
            toId beaconId
                |> Maybe.map (\id -> BeaconBox id box)
    in
    { cursor = json.cursor
    , beacons = List.filterMap convert json.beacons
    }


startEvent :
    (Int -> Maybe dragId)
    -> BeaconJson
    -> Point
    -> Decode.Decoder (Msg dragId dropId hoverId)
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


dragMove :
    DragData dropId
    -> ( DraggedItem dragId, cache )
    -> Transition dragId dropId hoverId cache
dragMove data pair =
    let
        move : DraggedItem dragId -> DraggedItem dragId
        move draggedItem =
            { draggedItem | cursorOnScreen = data.cursor }
    in
    DragMove <|
        case ( pair, boundingBeaconId data ) of
            ( ( draggedItem, cache ), Nothing ) ->
                Dragging <| ( move draggedItem, cache )

            ( ( draggedItem, cache ), Just dropBeaconId ) ->
                Hovering <| ( HoverState (move draggedItem) dropBeaconId, cache )


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


attribute : Int -> Element.Attribute msg
attribute beaconId =
    Element.htmlAttribute <|
        Html.Attributes.attribute "data-beacon"
            (Encode.encode 0 <| Encode.int beaconId)
