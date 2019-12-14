port module Creation exposing (..)

import Api exposing (ApiResult, noFilters)
import Array exposing (Array)
import Colors exposing (..)
import Dict exposing (Dict)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode
import LifeBlock exposing (LifeBlock)
import Lifepath exposing (Lead, Lifepath, Skill, StatMod, StatModType(..))
import Session exposing (..)
import String.Extra exposing (toTitleCase)
import Trait exposing (Trait)



-- MODEL


type alias Model =
    { session : Session
    , sidebarLifepaths : Status (List LifeBlock)
    , blocks : Dict Int LifeBlock
    , nextBeaconId : Int
    , draggedBlock : Maybe DraggedBlock
    }


type alias DraggedBlock =
    { id : Int
    , cursorOnScreen : Coords
    , cursorOnDraggable : Coords
    }


type Status a
    = Loading
    | Loaded a
    | Failed


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , sidebarLifepaths = Loading
      , blocks = Dict.empty
      , nextBeaconId = 1
      , draggedBlock = Nothing
      }
    , Api.listLifepaths GotLifepaths { noFilters | born = Just True }
    )



-- UPDATE


type Msg
    = GotLifepaths (ApiResult (List Lifepath))
    | Drag DragEvent
    | NoOp


type DragEvent
    = Start DraggedBlock
    | Move DragData
    | Stop DragData


type alias DragData =
    { cursor : Coords
    , beacons : List Beacon
    }


type alias Beacon =
    { beaconId : Int
    , box : Rect
    }


type alias Coords =
    { x : Float, y : Float }


type alias Rect =
    { x : Float
    , y : Float
    , width : Float
    , height : Float
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotLifepaths (Ok lifepaths) ->
            let
                ( newModel, blocks ) =
                    LifeBlock.addBatch model lifepaths
            in
            ( { newModel | sidebarLifepaths = Loaded blocks }
            , Cmd.none
            )

        GotLifepaths (Err error) ->
            ( { model | sidebarLifepaths = Failed }
            , Cmd.none
            )

        Drag (Start draggedBlock) ->
            ( { model | draggedBlock = Just draggedBlock }
            , Cmd.none
            )

        Drag (Move data) ->
            case model.draggedBlock of
                Nothing ->
                    ( model, Cmd.none )

                Just block ->
                    ( updateDraggedBlock model block data, Cmd.none )

        Drag (Stop data) ->
            -- TODO what did we drop it on/in?
            -- need to find closest bounding beacon
            ( { model | draggedBlock = Nothing }
            , Cmd.none
            )

        NoOp ->
            ( model, Cmd.none )


updateDraggedBlock : Model -> DraggedBlock -> DragData -> Model
updateDraggedBlock model { id, cursorOnDraggable } { cursor } =
    case Dict.get id model.blocks of
        Just block ->
            { model
                | draggedBlock =
                    Just
                        { id = id
                        , cursorOnScreen = cursor
                        , cursorOnDraggable = cursorOnDraggable
                        }
            }

        Nothing ->
            model


view : Model -> Element Msg
view model =
    row [ width fill, height fill, spacing 40 ]
        [ viewSidebar model.sidebarLifepaths
        , viewMainArea []
        , viewDraggedBlock model.draggedBlock model.blocks
        ]


viewMainArea : List LifeBlock -> Element Msg
viewMainArea fragments =
    let
        filledSlots =
            List.map viewFragment fragments ++ [ openSlot ]

        slots =
            filledSlots
                ++ List.repeat
                    (8 - List.length filledSlots)
                    (el slotAttrs none)
    in
    row
        [ spacing 20
        , padding 40
        , centerX
        , centerY
        , height <| px 500
        , width (fillPortion 5)
        ]
        (List.take 4 slots)


viewFragment : LifeBlock -> Element Msg
viewFragment block =
    viewLifepath block.first { withBeacon = Just block.beaconId }


openSlot : Element Msg
openSlot =
    el (Border.width 1 :: slotAttrs) <|
        el [ centerX, centerY ] (text "+")


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


viewDraggedBlock : Maybe DraggedBlock -> Dict Int LifeBlock -> Element Msg
viewDraggedBlock draggedBlock blocks =
    let
        maybeBlock : Maybe LifeBlock
        maybeBlock =
            Maybe.map .id draggedBlock
                |> Maybe.andThen (\id -> Dict.get id blocks)

        top : DraggedBlock -> String
        top { cursorOnScreen, cursorOnDraggable } =
            String.fromFloat (cursorOnScreen.y - cursorOnDraggable.y) ++ "px"

        left : DraggedBlock -> String
        left { cursorOnScreen, cursorOnDraggable } =
            String.fromFloat (cursorOnScreen.x - cursorOnDraggable.x) ++ "px"
    in
    case ( maybeBlock, draggedBlock ) of
        ( Just block, Just dragged ) ->
            el
                ([ htmlAttribute <| Html.Attributes.style "position" "fixed"
                 , htmlAttribute <|
                    Html.Attributes.style "top" (top dragged)
                 , htmlAttribute <|
                    Html.Attributes.style "left" (left dragged)
                 , htmlAttribute <| Html.Attributes.style "list-style" "none"
                 , htmlAttribute <| Html.Attributes.style "padding" "0"
                 , htmlAttribute <| Html.Attributes.style "margin" "0"
                 , width <| px 300
                 ]
                    ++ userSelectNone
                )
                (viewLifepath block.first { withBeacon = Nothing })

        _ ->
            none


viewSidebar : Status (List LifeBlock) -> Element Msg
viewSidebar status =
    let
        viewBlock =
            \block ->
                viewLifepath block.first { withBeacon = Just block.beaconId }
    in
    column
        [ width (fillPortion 1)
        , height fill
        , Background.color Colors.darkened
        , Font.color Colors.white
        , spacing 20
        , padding 40
        ]
        (case status of
            Loading ->
                [ text "loading..." ]

            Failed ->
                [ text "couldn't load lifepaths" ]

            Loaded lifeBlocks ->
                List.map viewBlock lifeBlocks
        )


viewLifepath : Lifepath -> { withBeacon : Maybe Int } -> Element Msg
viewLifepath lifepath { withBeacon } =
    let
        defaultAttrs : List (Attribute Msg)
        defaultAttrs =
            [ Background.color Colors.white
            , Font.color Colors.black
            , Border.rounded 8
            , Border.color Colors.darkened
            , Border.width 1
            , padding 12
            , width <| px 300
            , spacing 10
            ]
                ++ userSelectNone

        attrs =
            case withBeacon of
                Just beaconId ->
                    beaconAttribute beaconId :: defaultAttrs

                Nothing ->
                    defaultAttrs
    in
    column attrs
        [ text <| toTitleCase lifepath.name
        , row [ width fill, spaceEvenly ]
            [ text (String.fromInt lifepath.years ++ " years")
            , text (String.fromInt lifepath.res ++ " res")
            , viewLifepathStat lifepath.statMod
            ]
        , viewSkills lifepath.skillPts lifepath.skills
        , viewTraits lifepath.traitPts lifepath.traits
        , viewLeads lifepath.leads
        ]


beaconAttribute : Int -> Attribute msg
beaconAttribute beaconId =
    htmlAttribute <|
        Html.Attributes.attribute "data-beacon"
            (Encode.encode 0 <| Encode.int beaconId)


viewLeads : List Lead -> Element Msg
viewLeads leads =
    let
        leadNames =
            String.join ", " <|
                List.map (\l -> toTitleCase <| .settingName l) leads
    in
    if List.length leads == 0 then
        none

    else
        paragraph []
            [ text <| "Leads: " ++ leadNames ]


viewTraits : Int -> List Trait -> Element Msg
viewTraits pts traits =
    let
        traitNames =
            String.join ", " <| List.map (\tr -> toTitleCase <| Trait.name tr) traits
    in
    case ( pts, List.length traits ) of
        ( 0, 0 ) ->
            none

        ( _, 0 ) ->
            paragraph []
                [ text ("Traits: " ++ String.fromInt pts) ]

        _ ->
            paragraph []
                [ text ("Traits: " ++ String.fromInt pts ++ ": " ++ traitNames) ]


viewSkills : Int -> List Skill -> Element Msg
viewSkills pts skills =
    let
        skillNames =
            String.join ", " <| List.map (\sk -> toTitleCase <| .displayName sk) skills
    in
    case ( pts, List.length skills ) of
        ( 0, 0 ) ->
            none

        ( _, 0 ) ->
            paragraph []
                [ text ("Skills: " ++ String.fromInt pts) ]

        _ ->
            paragraph []
                [ text ("Skills: " ++ String.fromInt pts ++ ": " ++ skillNames) ]


viewLifepathStat : Maybe StatMod -> Element Msg
viewLifepathStat statMod =
    case statMod of
        Nothing ->
            text <| "stat: --"

        Just mod ->
            text <| "stat: " ++ viewStatMod mod


viewStatMod : StatMod -> String
viewStatMod statMod =
    let
        prefix =
            -- zero is not a permitted value in the db
            if statMod.value > 0 then
                "+"

            else
                "-"

        suffix =
            case statMod.taip of
                Physical ->
                    " P"

                Mental ->
                    " M"

                Either ->
                    " M/P"

                Both ->
                    " M,P"
    in
    prefix ++ String.fromInt statMod.value ++ suffix



-- DRAG PORT


port dragEvents : (Decode.Value -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ dragEvents decodeDragEvents ]


decodeDragEvents : Decode.Value -> Msg
decodeDragEvents value =
    case Decode.decodeValue msgDecoder value of
        Ok msg ->
            msg

        Err err ->
            -- TODO handle js errors
            let
                oops =
                    Debug.log <| Decode.errorToString err
            in
            NoOp


msgDecoder : Decode.Decoder Msg
msgDecoder =
    Decode.succeed BeaconJson
        |> required "type" eventDecoder
        |> required "cursor" coordsDecoder
        |> required "beacons" beaconsDecoder
        |> optional "startBeaconId" (Decode.map Just Decode.string) Nothing
        |> optional "cursorOnDraggable" (Decode.map Just coordsDecoder) Nothing
        |> Decode.andThen dragEvent


dragData : BeaconJson -> DragData
dragData json =
    { cursor = json.cursor
    , beacons =
        List.map
            (\( beaconId, box ) -> Beacon beaconId box)
            json.beacons
    }


dragEvent : BeaconJson -> Decode.Decoder Msg
dragEvent json =
    let
        data =
            dragData json
    in
    Decode.map Drag <|
        case json.eventType of
            StartEvent ->
                startEvent json data.cursor

            MoveEvent ->
                Decode.succeed <| Move data

            StopEvent ->
                Decode.succeed <| Stop data


startEvent : BeaconJson -> Coords -> Decode.Decoder DragEvent
startEvent { startBeaconId, cursorOnDraggable } cursor =
    case ( Maybe.andThen String.toInt startBeaconId, cursorOnDraggable ) of
        ( Just id, Just onDraggable ) ->
            Decode.succeed <| Start <| DraggedBlock id cursor onDraggable

        _ ->
            Decode.fail "Recieved start event with no beacon id"


type EventType
    = StartEvent
    | MoveEvent
    | StopEvent


type alias BeaconJson =
    { eventType : EventType
    , cursor : Coords
    , beacons : List ( Int, Rect )
    , startBeaconId : Maybe String
    , cursorOnDraggable : Maybe Coords
    }


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


coordsDecoder : Decode.Decoder Coords
coordsDecoder =
    Decode.map2 Coords
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)


beaconsDecoder : Decode.Decoder (List ( Int, Rect ))
beaconsDecoder =
    Decode.list
        (Decode.map2
            Tuple.pair
            (Decode.field "id" Decode.int)
            rectDecoder
        )


rectDecoder : Decode.Decoder Rect
rectDecoder =
    Decode.map4 Rect
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)
        (Decode.field "width" Decode.float)
        (Decode.field "height" Decode.float)


userSelectNone : List (Attribute msg)
userSelectNone =
    List.map (\key -> htmlAttribute <| Html.Attributes.style key "none")
        [ "-webkit-touch-callout"
        , "-webkit-user-select"
        , "-khtml-user-select"
        , "-moz-user-select"
        , "-ms-user-select"
        , "user-select"
        ]
