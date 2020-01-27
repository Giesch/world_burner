port module Creation exposing (..)

import Api exposing (ApiResult, noFilters)
import Colors exposing (..)
import Common
import Dict exposing (Dict)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Geom exposing (Box, Point)
import Html
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode
import Lifepath exposing (Lead, Lifepath, Skill, StatMod, StatModType(..))
import Process
import Session exposing (..)
import Set exposing (Set)
import String.Extra exposing (toTitleCase)
import Task
import Trait exposing (Trait)



-- MODEL


type alias Model =
    { session : Session
    , sidebarLifepaths : Status (List Int)
    , searchFilters : Api.LifepathFilters
    , dragBeacons : Dict Int DragBeacon
    , dropBeacons : Dict Int DropBeacon
    , benchBlocks : List Int
    , nextBeaconId : Int
    , dragState : DragState
    }


type DragBeacon
    = SidebarPath LifeBlock
    | BenchBlock LifeBlock


type alias LifeBlock =
    { path : Lifepath
    , beaconId : Int
    }


dragBlock : DragBeacon -> LifeBlock
dragBlock beacon =
    -- TODO think about splitting these into two dicts?
    case beacon of
        SidebarPath block ->
            block

        BenchBlock block ->
            block


type DropBeacon
    = Static StaticBeacon


type DragState
    = NotDragging
    | Dragging DraggedBlock
    | Hovering HoverState


type alias HoverState =
    { draggedBlock : DraggedBlock
    , hoveredDropBeacon : Int
    }


hoverState : DragState -> Maybe HoverState
hoverState dragState =
    case dragState of
        Hovering hover ->
            Just hover

        _ ->
            Nothing


getDraggedBlock : DragState -> Maybe DraggedBlock
getDraggedBlock dragState =
    case dragState of
        NotDragging ->
            Nothing

        Dragging draggedBlock ->
            Just draggedBlock

        Hovering { draggedBlock } ->
            Just draggedBlock


type alias DraggedBlock =
    { beaconId : Int
    , cursorOnScreen : Point
    , cursorOnDraggable : Point
    }


type Status a
    = Loading
    | Loaded a
    | Failed


init : Session -> ( Model, Cmd Msg )
init session =
    let
        searchFilters : Api.LifepathFilters
        searchFilters =
            { noFilters | born = Just True }
    in
    ( { session = session
      , sidebarLifepaths = Loading
      , searchFilters = searchFilters
      , dragBeacons = Dict.empty
      , dropBeacons = initialDropBeacons
      , nextBeaconId = 1
      , benchBlocks = []
      , dragState = NotDragging
      }
    , fetchLifepaths searchFilters
    )


initialDropBeacons : Dict Int DropBeacon
initialDropBeacons =
    [ OpenSlot ]
        |> List.map (\beacon -> ( staticBeaconId beacon, Static beacon ))
        |> Dict.fromList


{-| Beacons with non-generated beacon ids.
They have negative beacon ids to avoid overlap with the generated ones.
-}
staticBeaconId : StaticBeacon -> Int
staticBeaconId beacon =
    case beacon of
        OpenSlot ->
            -1


type StaticBeacon
    = OpenSlot


fetchLifepaths : Api.LifepathFilters -> Cmd Msg
fetchLifepaths searchFilters =
    Api.listLifepaths GotLifepaths searchFilters



-- UPDATE


type Msg
    = GotLifepaths (ApiResult (List Lifepath))
    | DragMsg DragEvent
    | DeleteBenchBlock Int
    | EnteredSearchText String
    | SearchTimePassed String
    | ClickedBornCheckbox Bool
    | NoOp


type DragEvent
    = Start DraggedBlock
    | Move DragData
    | Stop DragData


type alias DragData =
    { cursor : Point
    , beacons : List BeaconBox
    }


type alias BeaconBox =
    { beaconId : Int
    , box : Box
    }


type alias Box =
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
                cleanModel =
                    cleanSidebarBeacons model

                ( newModel, blocks ) =
                    addBatch cleanModel lifepaths SidebarPath
            in
            ( { newModel | sidebarLifepaths = Loaded (List.map .beaconId blocks) }
            , Cmd.none
            )

        GotLifepaths (Err error) ->
            let
                cleanModel =
                    cleanSidebarBeacons model
            in
            ( { cleanModel | sidebarLifepaths = Failed }
            , Cmd.none
            )

        DragMsg (Start draggedBlock) ->
            let
                newModel =
                    case Dict.get draggedBlock.beaconId model.dragBeacons of
                        Just _ ->
                            { model | dragState = Dragging draggedBlock }

                        Nothing ->
                            model
            in
            ( newModel, Cmd.none )

        DragMsg (Move data) ->
            ( moveDraggedBlock model data, Cmd.none )

        DragMsg (Stop data) ->
            ( dropDraggedBlock model data, Cmd.none )

        DeleteBenchBlock id ->
            ( deleteBenchBlock model id, Cmd.none )

        EnteredSearchText input ->
            let
                searchFilters =
                    model.searchFilters

                searchTerm =
                    if String.length input > 0 then
                        Just input

                    else
                        Nothing
            in
            ( { model | searchFilters = { searchFilters | searchTerm = searchTerm } }
            , beginSearchDebounce input
            )

        SearchTimePassed searchTerm ->
            ( model
            , maybeSearch searchTerm model.searchFilters
            )

        ClickedBornCheckbox checked ->
            let
                updateFilters filters =
                    if checked then
                        { filters | born = Just True }

                    else
                        { filters | born = Nothing }

                searchFilters =
                    updateFilters model.searchFilters
            in
            ( { model | searchFilters = searchFilters }
            , fetchLifepaths searchFilters
            )

        NoOp ->
            ( model, Cmd.none )


deleteBenchBlock : Model -> Int -> Model
deleteBenchBlock model id =
    { model
        | dragBeacons = Dict.remove id model.dragBeacons
        , benchBlocks =
            List.filter (\beaconId -> beaconId /= id) model.benchBlocks
    }


addBatch : Model -> List Lifepath -> (LifeBlock -> DragBeacon) -> ( Model, List LifeBlock )
addBatch ({ nextBeaconId, dragBeacons } as model) lifepaths constructor =
    let
        makeBlock : Lifepath -> ( Int, List LifeBlock ) -> ( Int, List LifeBlock )
        makeBlock path ( nextId, blockList ) =
            ( nextId + 1, LifeBlock path nextId :: blockList )

        ( newNextId, blocksWithIds ) =
            List.foldl makeBlock ( nextBeaconId, [] ) lifepaths

        insertBlock : LifeBlock -> Dict Int DragBeacon -> Dict Int DragBeacon
        insertBlock block dict =
            Dict.insert block.beaconId (constructor block) dict

        newBlocks : Dict Int DragBeacon
        newBlocks =
            List.foldl insertBlock dragBeacons blocksWithIds
    in
    ( { model | nextBeaconId = newNextId, dragBeacons = newBlocks }
    , List.reverse blocksWithIds
    )


nearestDropBeacon : Dict Int DropBeacon -> DragData -> Maybe BeaconBox
nearestDropBeacon dropBeacons { cursor, beacons } =
    let
        dropBeaconIds : Set Int
        dropBeaconIds =
            Set.fromList <| Dict.keys dropBeacons

        isDropBeacon : BeaconBox -> Bool
        isDropBeacon beacon =
            Set.member beacon.beaconId dropBeaconIds

        distanceFromCursor : BeaconBox -> Float
        distanceFromCursor =
            .box >> Geom.center >> Geom.distance cursor
    in
    beacons
        |> List.filter isDropBeacon
        |> Common.minimumBy distanceFromCursor


boundingDropBeacon : Dict Int DropBeacon -> DragData -> Maybe BeaconBox
boundingDropBeacon dropBeacons data =
    -- TODO use a range instead of bound
    nearestDropBeacon dropBeacons data
        |> Common.keepIf (\beacon -> Geom.bounds beacon.box data.cursor)


draggedBlockAndDropBeaconId : Model -> DragData -> ( Maybe DraggedBlock, Maybe Int )
draggedBlockAndDropBeaconId model data =
    ( getDraggedBlock model.dragState
    , boundingDropBeacon model.dropBeacons data |> Maybe.map .beaconId
    )


moveDraggedBlock : Model -> DragData -> Model
moveDraggedBlock model data =
    let
        move : DraggedBlock -> DraggedBlock
        move draggedBlock =
            { draggedBlock | cursorOnScreen = data.cursor }

        drag : DraggedBlock -> DragState
        drag draggedBlock =
            Dragging <| move draggedBlock

        hover : DraggedBlock -> Int -> DragState
        hover draggedBlock dropBeaconId =
            Hovering <| HoverState (move draggedBlock) dropBeaconId
    in
    case draggedBlockAndDropBeaconId model data of
        ( Nothing, _ ) ->
            model

        ( Just draggedBlock, Nothing ) ->
            { model | dragState = drag draggedBlock }

        ( Just draggedBlock, Just dropBeaconId ) ->
            { model | dragState = hover draggedBlock dropBeaconId }


dropDraggedBlock : Model -> DragData -> Model
dropDraggedBlock model data =
    let
        dropAndDoNothing : Model
        dropAndDoNothing =
            { model | dragState = NotDragging }
    in
    case draggedBlockAndDropBeaconId model data of
        ( Just draggedBlock, Just dropBeaconId ) ->
            let
                theBeacon : Maybe DropBeacon
                theBeacon =
                    Dict.get dropBeaconId model.dropBeacons
            in
            -- TODO
            -- need to:
            -- look up the dropBeacon type by the id
            -- look up the dragBeacon type by its id
            -- find the validation for that beacon
            -- execute that validation, short circuiting
            -- find the transformation for that beacon
            -- execute that transformation
            Debug.todo "do the drop"

        _ ->
            dropAndDoNothing


cleanSidebarBeacons : Model -> Model
cleanSidebarBeacons model =
    let
        sidebarIds : Set Int
        sidebarIds =
            case model.sidebarLifepaths of
                Loaded blocks ->
                    Set.fromList blocks

                Loading ->
                    Set.empty

                Failed ->
                    Set.empty

        dragBeacons : Dict Int DragBeacon
        dragBeacons =
            Dict.filter (\id _ -> not <| Set.member id sidebarIds) model.dragBeacons
    in
    { model | dragBeacons = dragBeacons }


maybeSearch : String -> Api.LifepathFilters -> Cmd Msg
maybeSearch oldInput searchFilters =
    let
        shouldSearch val =
            String.length val >= 2 && val == oldInput
    in
    if Maybe.map shouldSearch searchFilters.searchTerm == Just True then
        fetchLifepaths searchFilters

    else
        Cmd.none


beginSearchDebounce : String -> Cmd Msg
beginSearchDebounce input =
    Process.sleep 500
        |> Task.perform (\_ -> SearchTimePassed input)


bump : Model -> ( Int, Model )
bump model =
    -- TODO use this on drop
    -- always copy the dragged block
    -- then maybe delete the original and its references
    ( model.nextBeaconId
    , { model | nextBeaconId = model.nextBeaconId + 1 }
    )



-- VIEW


view : Model -> Element Msg
view model =
    row [ width fill, height fill, scrollbarY, spacing 40 ]
        [ viewSidebar model
        , viewMainArea
            (lookupBenchBlocks model)
            (hoverState model.dragState)
            model.dragBeacons
        , viewDraggedBlock
            (getDraggedBlock model.dragState)
            model.dragBeacons
        ]


lookupBenchBlocks : Model -> List LifeBlock
lookupBenchBlocks { dragBeacons, benchBlocks } =
    benchBlocks
        |> List.map (Common.lookup dragBeacons)
        |> List.filterMap identity
        |> List.map dragBlock


viewMainArea : List LifeBlock -> Maybe HoverState -> Dict Int DragBeacon -> Element Msg
viewMainArea fragments hover dragBeacons =
    let
        filledSlots =
            List.map viewFragment fragments ++ [ openSlot hover dragBeacons ]

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
        , width fill
        ]
        (List.take 4 slots)


viewFragment : LifeBlock -> Element Msg
viewFragment block =
    column [ width <| px 350 ]
        [ Input.button [ alignRight ]
            { onPress = Just <| DeleteBenchBlock block.beaconId
            , label = text "X"
            }
        , viewLifepath block.path { withBeacon = Just block.beaconId }
        ]


hoveringLifeBlock : Model -> Int -> Maybe LifeBlock
hoveringLifeBlock model dropBeaconId =
    case model.dragState of
        Hovering { draggedBlock, hoveredDropBeacon } ->
            case Dict.get draggedBlock.beaconId model.dragBeacons of
                Just something ->
                    Debug.todo "wat"

                Nothing ->
                    Nothing

        _ ->
            Nothing


openSlot : Maybe HoverState -> Dict Int DragBeacon -> Element Msg
openSlot hover dragBeacons =
    -- TODO the argument should be the maybe hovering block instead of the dragBeacons
    let
        emptyView =
            el
                (beaconAttribute (staticBeaconId OpenSlot)
                    :: Border.width 1
                    :: slotAttrs
                )
                (el [ centerX, centerY ] <| text "+")

        beingHovered : Bool
        beingHovered =
            hover
                |> Maybe.map
                    (\state -> state.hoveredDropBeacon == staticBeaconId OpenSlot)
                |> Maybe.withDefault False

        hoveringBlock : Maybe LifeBlock
        hoveringBlock =
            hover
                |> Maybe.map (.draggedBlock >> .beaconId)
                |> Maybe.andThen (Common.lookup dragBeacons)
                |> Maybe.map dragBlock
    in
    case ( beingHovered, hoveringBlock ) of
        ( True, Just block ) ->
            viewPhantomFragment block (staticBeaconId OpenSlot)

        _ ->
            emptyView


{-| Like viewFragment, but for a hypothetical drop
It uses only the original beacon id
-}
viewPhantomFragment : LifeBlock -> Int -> Element Msg
viewPhantomFragment block beaconId =
    column
        (beaconAttribute beaconId :: slotAttrs)
        [ Input.button [ alignRight ]
            { onPress = Just <| DeleteBenchBlock block.beaconId
            , label = text "X"
            }
        , viewLifepath block.path { withBeacon = Nothing }
        ]


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


viewDraggedBlock : Maybe DraggedBlock -> Dict Int DragBeacon -> Element Msg
viewDraggedBlock draggedBlock blocks =
    let
        maybeBlock : Maybe DragBeacon
        maybeBlock =
            Maybe.map .beaconId draggedBlock
                |> Maybe.andThen (Common.lookup blocks)

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
                 , width lifepathWidth
                 ]
                    ++ userSelectNone
                )
                (viewDraggedPath block)

        _ ->
            none


viewDraggedPath : DragBeacon -> Element Msg
viewDraggedPath beacon =
    case beacon of
        SidebarPath block ->
            viewLifepath block.path { withBeacon = Nothing }

        BenchBlock block ->
            viewLifepath block.path { withBeacon = Nothing }


viewSidebar : Model -> Element Msg
viewSidebar model =
    column
        [ width <| px 350
        , height fill
        , scrollbarY
        , Background.color Colors.darkened
        , Font.color Colors.white
        , spacing 20
        ]
        [ viewLifepathSearch model.searchFilters
        , viewSidebarLifepaths <|
            lookupSidebarLifepaths model.dragBeacons model.sidebarLifepaths
        ]


lookupSidebarLifepaths : Dict Int DragBeacon -> Status (List Int) -> Status (List LifeBlock)
lookupSidebarLifepaths beacons status =
    case status of
        Loading ->
            Loading

        Failed ->
            Failed

        Loaded sidebarIds ->
            sidebarIds
                |> List.map (Common.lookup beacons)
                |> List.filterMap identity
                |> List.map dragBlock
                |> Loaded


viewSidebarLifepaths : Status (List LifeBlock) -> Element Msg
viewSidebarLifepaths sidebarLifepaths =
    let
        viewBlock =
            \block ->
                viewLifepath block.path { withBeacon = Just block.beaconId }
    in
    case sidebarLifepaths of
        Loading ->
            text "loading..."

        Failed ->
            text "couldn't load lifepaths"

        Loaded lifeBlocks ->
            column [ spacing 20, padding 20, width fill, height fill, scrollbarY ]
                (List.map viewBlock lifeBlocks)


viewLifepathSearch : Api.LifepathFilters -> Element Msg
viewLifepathSearch { searchTerm, born } =
    column [ alignRight, padding 40, width fill ]
        [ bornCheckbox <| Maybe.withDefault False born
        , searchInput <| Maybe.withDefault "" searchTerm
        ]


bornCheckbox : Bool -> Element Msg
bornCheckbox checked =
    Input.checkbox [ alignRight ]
        { onChange = ClickedBornCheckbox
        , icon = Input.defaultCheckbox
        , checked = checked
        , label = Input.labelLeft [ alignRight ] <| text "Born"
        }


searchInput : String -> Element Msg
searchInput searchTerm =
    Input.search [ Font.color Colors.black ]
        { onChange = EnteredSearchText
        , text = searchTerm
        , placeholder = Nothing
        , label = Input.labelAbove [] <| text "Search"
        }


lifepathWidth : Length
lifepathWidth =
    px 300


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
            , width lifepathWidth
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


dragData : BeaconJson -> DragData
dragData json =
    { cursor = json.cursor
    , beacons =
        List.map
            (\( beaconId, box ) -> BeaconBox beaconId box)
            json.beacons
    }


dragEvent : BeaconJson -> Decode.Decoder Msg
dragEvent json =
    let
        data : DragData
        data =
            dragData json
    in
    Decode.map DragMsg <|
        case json.eventType of
            StartEvent ->
                startEvent json data.cursor

            MoveEvent ->
                Decode.succeed <| Move data

            StopEvent ->
                Decode.succeed <| Stop data


startEvent : BeaconJson -> Point -> Decode.Decoder DragEvent
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
    , cursor : Point
    , beacons : List ( Int, Box )
    , startBeaconId : Maybe String
    , cursorOnDraggable : Maybe Point
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


beaconsDecoder : Decode.Decoder (List ( Int, Box ))
beaconsDecoder =
    Decode.list
        (Decode.map2
            Tuple.pair
            (Decode.field "id" Decode.int)
            Geom.boxDecoder
        )


closestBoundingBeacon : DragData -> Maybe BeaconBox
closestBoundingBeacon { cursor, beacons } =
    beacons
        |> List.sortBy (Geom.distance cursor << Geom.center << .box)
        |> List.head
        |> Common.keepIf (\beacon -> Geom.bounds beacon.box cursor)
