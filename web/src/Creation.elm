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
import Json.Decode.Pipeline exposing (required)
import LifeBlock exposing (LifeBlock)
import Lifepath exposing (Lead, Lifepath, Skill, StatMod, StatModType(..))
import Session exposing (..)
import String.Extra exposing (toTitleCase)
import Trait exposing (Trait)


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
                 ]
                    ++ userSelectNone
                )
                (viewLifepath block.first)

        _ ->
            none


type alias DraggedBlock =
    { id : Int
    , cursorOnScreen : Coords
    , cursorOnDraggable : Coords
    }


type alias Model =
    { session : Session
    , sidebarLifepaths : Status (List Lifepath)
    , blocks : Dict Int LifeBlock
    , nextBlockId : Int
    , draggedBlock : Maybe DraggedBlock
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
      , nextBlockId = 1
      , draggedBlock = Nothing
      }
    , Api.listLifepaths GotLifepaths { noFilters | born = Just True }
    )


type Msg
    = GotLifepaths (ApiResult (List Lifepath))
    | Drag DragEvent
    | NoOp


type DragEvent
    = Start DraggedItem
    | Move DragData
    | Stop DragData


type alias Dragged item =
    { item : item
    , cursorOnScreen : Coords
    , cursorOnDraggable : Coords
    }


type DraggedItem
    = Block (Dragged Int)
    | Path (Dragged Lifepath)


type alias DragData =
    { cursor : Coords
    , beacons : List Beacon
    }


type alias Beacon =
    { blockId : Int
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


initializeBlock : Model -> DraggedItem -> Model
initializeBlock model draggedItem =
    let
        withDraggedBlock : Model -> DraggedBlock -> Model
        withDraggedBlock aModel draggedBlock =
            { aModel | draggedBlock = Just draggedBlock }
    in
    case draggedItem of
        Block { item, cursorOnScreen, cursorOnDraggable } ->
            withDraggedBlock model <|
                DraggedBlock item cursorOnScreen cursorOnDraggable

        Path { item, cursorOnScreen, cursorOnDraggable } ->
            let
                ( newModel, id ) =
                    LifeBlock.dragNewBlock model <| LifeBlock.fromPath item
            in
            withDraggedBlock newModel <|
                DraggedBlock id cursorOnScreen cursorOnDraggable


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotLifepaths (Ok bornLifepaths) ->
            ( { model | sidebarLifepaths = Loaded bornLifepaths }
            , Cmd.none
            )

        GotLifepaths (Err error) ->
            ( { model | sidebarLifepaths = Failed }
            , Cmd.none
            )

        Drag (Start draggedItem) ->
            ( initializeBlock model draggedItem
            , Cmd.none
            )

        Drag (Move data) ->
            case model.draggedBlock of
                Nothing ->
                    ( model, Cmd.none )

                Just block ->
                    -- TODO update dragged Block location
                    -- TODO validations/check cached validations
                    ( updateDraggedBlock model block data, Cmd.none )

        Drag (Stop data) ->
            -- TODO what did we drop it on/in?
            -- find closest valid beacon
            -- combine the blocks (append one to the other)
            -- remove the dragged block from the dict if neccessary?
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
    row [ width fill, height fill ]
        [ column
            [ width (fillPortion 1)
            , height fill
            , Background.color Colors.darkened
            , Font.color Colors.white
            , spacing 20
            , padding 40
            ]
            (viewSidebar model.sidebarLifepaths)
        , column [ width (fillPortion 5), height fill ]
            [ el [ centerX, centerY ] <| none ]
        , viewDraggedBlock model.draggedBlock model.blocks
        ]


viewSidebar : Status (List Lifepath) -> List (Element Msg)
viewSidebar status =
    case status of
        Loading ->
            [ text "loading..." ]

        Failed ->
            [ text "couldn't load lifepaths" ]

        Loaded lifepaths ->
            List.map viewLifepath lifepaths


viewLifepath : Lifepath -> Element Msg
viewLifepath lifepath =
    column
        ([ Background.color Colors.white
         , Font.color Colors.black
         , Border.rounded 8
         , padding 12
         , width fill
         , spacing 10
         , onPointerDown lifepath
         ]
            ++ userSelectNone
        )
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
        text <| "Leads: " ++ leadNames


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
            text ("Traits: " ++ String.fromInt pts)

        _ ->
            text ("Traits: " ++ String.fromInt pts ++ ": " ++ traitNames)


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
            text ("Skills: " ++ String.fromInt pts)

        _ ->
            text ("Skills: " ++ String.fromInt pts ++ ": " ++ skillNames)


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
        |> required "beacons" handlersDecoder
        |> Decode.map dragEvent


dragData : BeaconJson -> DragData
dragData json =
    { cursor = json.cursor
    , beacons =
        List.map
            (\( blockId, box ) -> Beacon blockId box)
            json.handlers
    }


dragEvent : BeaconJson -> Msg
dragEvent json =
    let
        data =
            dragData json
    in
    Drag <|
        case json.eventType of
            -- StartEvent ->
            --     Start <| closestRect data.cursor data.beacons
            MoveEvent ->
                Move data

            StopEvent ->
                Stop data


type EventType
    = -- StartEvent -- TODO remove this from js?
      MoveEvent
    | StopEvent


type alias BeaconJson =
    { eventType : EventType
    , cursor : Coords
    , handlers : List ( Int, Rect )
    }


eventDecoder : Decode.Decoder EventType
eventDecoder =
    Decode.string
        |> Decode.andThen
            (\eventType ->
                case eventType of
                    -- TODO remove this from the js?
                    -- "start" ->
                    --     Decode.succeed StartEvent
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


handlersDecoder : Decode.Decoder (List ( Int, Rect ))
handlersDecoder =
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



-- Functions for manipulating Rects and Coords


{-| Finds the id of the block whose center is closest to the cursor,
and still within the beacon's bounding box.
-}
closestRect : Coords -> List Beacon -> Maybe Int
closestRect cursor beacons =
    beacons
        |> List.sortBy (distance cursor << center << .box)
        |> List.head
        |> keepIf (containedBy cursor << .box)
        |> Maybe.map .blockId


keepIf : (a -> Bool) -> Maybe a -> Maybe a
keepIf fn maybe =
    Maybe.andThen
        (\item ->
            if fn item then
                Just item

            else
                Nothing
        )
        maybe


containedBy : Coords -> Rect -> Bool
containedBy { x, y } box =
    (x > box.x)
        && (y > box.y)
        && (x < (box.x + box.width))
        && (y < (box.y + box.height))


center : Rect -> Coords
center { x, y, width, height } =
    { x = x + (width / 2)
    , y = y + (height / 2)
    }


distance : Coords -> Coords -> Float
distance coords1 coords2 =
    let
        dx =
            coords1.x - coords2.x

        dy =
            coords1.y - coords2.y
    in
    sqrt ((dx ^ 2) + (dy ^ 2))


onPointerDown : Lifepath -> Attribute Msg
onPointerDown lifepath =
    -- TODO name this better
    let
        dragged : Coords -> Coords -> Dragged Lifepath
        dragged onScreen onDraggable =
            { item = lifepath
            , cursorOnScreen = onScreen
            , cursorOnDraggable = onDraggable
            }

        drag : Coords -> Coords -> Msg
        drag cursorOnScreen cursorOnDraggable =
            Drag <| Start <| Path <| dragged cursorOnScreen cursorOnDraggable
    in
    htmlAttribute <|
        Html.Events.on "pointerdown"
            (Decode.map2 drag
                cursorPositionDecoder
                cursorOffsetDecoder
            )


cursorPositionDecoder : Decode.Decoder Coords
cursorPositionDecoder =
    Decode.map2 Coords
        (Decode.field "clientX" Decode.float)
        (Decode.field "clientY" Decode.float)


cursorOffsetDecoder : Decode.Decoder Coords
cursorOffsetDecoder =
    Decode.map2 Coords
        (Decode.field "offsetX" Decode.float)
        (Decode.field "offsetY" Decode.float)


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
