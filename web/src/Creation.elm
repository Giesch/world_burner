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
    , draggedBlock : Maybe DraggedBlock
    }


type DragBeacon
    = SidebarPath LifeBlock
    | BenchBlock LifeBlock


type alias LifeBlock =
    { first : Lifepath
    , rest : List Lifepath
    , beaconId : Int
    }


blockPaths : LifeBlock -> List Lifepath
blockPaths { first, rest } =
    first :: rest


dragBlock : DragBeacon -> LifeBlock
dragBlock beacon =
    case beacon of
        SidebarPath block ->
            block

        BenchBlock block ->
            block


type DropBeacon
    = Static StaticBeacon


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
      , draggedBlock = Nothing
      , benchBlocks = []
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
    | DeleteLifeBlock Int
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
                        Just (SidebarPath referenceBlock) ->
                            copyOnDrag model draggedBlock referenceBlock

                        Just (BenchBlock referenceBlock) ->
                            pickupOnDrag model draggedBlock referenceBlock

                        _ ->
                            model
            in
            ( newModel, Cmd.none )

        DragMsg (Move data) ->
            ( moveDraggedBlock model data, Cmd.none )

        DragMsg (Stop data) ->
            case closestBoundingBeacon data of
                Nothing ->
                    ( cleanUpDraggedBlock model, Cmd.none )

                Just dropBeacon ->
                    ( dropOnBeacon model dropBeacon data.cursor
                    , Cmd.none
                    )

        DeleteLifeBlock id ->
            let
                dragBeacons : Dict Int DragBeacon
                dragBeacons =
                    Dict.remove id model.dragBeacons

                benchBlocks : List Int
                benchBlocks =
                    List.filter (\beaconId -> beaconId /= id) model.benchBlocks
            in
            ( { model | dragBeacons = dragBeacons, benchBlocks = benchBlocks }
            , Cmd.none
            )

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
                searchFilters =
                    model.searchFilters

                newSearchFilters =
                    if checked then
                        { searchFilters | born = Just True }

                    else
                        { searchFilters | born = Nothing }
            in
            ( { model | searchFilters = newSearchFilters }
            , fetchLifepaths newSearchFilters
            )

        NoOp ->
            ( model, Cmd.none )


addBatch : Model -> List Lifepath -> (LifeBlock -> DragBeacon) -> ( Model, List LifeBlock )
addBatch ({ nextBeaconId, dragBeacons } as model) lifepaths constructor =
    let
        makeBlock : Lifepath -> ( Int, List LifeBlock ) -> ( Int, List LifeBlock )
        makeBlock path ( nextId, blockList ) =
            ( nextId + 1, LifeBlock path [] nextId :: blockList )

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


moveDraggedBlock : Model -> DragData -> Model
moveDraggedBlock model data =
    let
        updateDraggedBlock : DraggedBlock -> Model
        updateDraggedBlock draggedBlock =
            { model | draggedBlock = Just <| move draggedBlock }

        move : DraggedBlock -> DraggedBlock
        move draggedBlock =
            { draggedBlock | cursorOnScreen = data.cursor }
    in
    model.draggedBlock
        |> Maybe.map updateDraggedBlock
        |> Maybe.withDefault model


placeDraggedBlock : Model -> DragData -> Model
placeDraggedBlock model data =
    -- TODO how do we manage 2 things with the same id?
    -- which one is the phantom copy? do we just cache an undo state?
    Debug.todo "put a copy in the right spot; handle ids"


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


dropOnBeacon : Model -> BeaconBox -> Point -> Model
dropOnBeacon model dropBeacon cursor =
    let
        draggedBlock : Maybe DragBeacon
        draggedBlock =
            model.draggedBlock
                |> Maybe.map .beaconId
                |> Maybe.andThen (Common.lookup model.dragBeacons)

        doDrop : LifeBlock -> Model
        doDrop block =
            let
                dragBeacons =
                    Dict.insert block.beaconId
                        (BenchBlock block)
                        model.dragBeacons
            in
            { model
                | benchBlocks = model.benchBlocks ++ [ block.beaconId ]
                , dragBeacons = dragBeacons
                , draggedBlock = Nothing
            }

        droppedOn : Maybe DropBeacon
        droppedOn =
            Dict.get dropBeacon.beaconId model.dropBeacons
    in
    case ( draggedBlock, droppedOn ) of
        ( Nothing, _ ) ->
            model

        ( Just (SidebarPath _), Nothing ) ->
            cleanUpDraggedBlock model

        ( Just (BenchBlock _), Nothing ) ->
            -- TODO clean up the origin location
            cleanUpDraggedBlock model

        ( Just (SidebarPath lifeBlock), Just (Static OpenSlot) ) ->
            doDrop lifeBlock

        ( Just (BenchBlock lifeBlock), Just (Static OpenSlot) ) ->
            Debug.todo "remove it from where it was then do drop"


cleanUpDraggedBlock : Model -> Model
cleanUpDraggedBlock model =
    case model.draggedBlock of
        Nothing ->
            model

        Just block ->
            { model
                | draggedBlock = Nothing
                , dragBeacons = Dict.remove block.beaconId model.dragBeacons
            }


copyOnDrag : Model -> DraggedBlock -> LifeBlock -> Model
copyOnDrag model draggedBlock lifeBlock =
    let
        ( newId, newModel ) =
            bump model

        newDraggedBlock : DraggedBlock
        newDraggedBlock =
            { draggedBlock | beaconId = newId }

        sidebarPath : DragBeacon
        sidebarPath =
            SidebarPath { lifeBlock | beaconId = newId }
    in
    { newModel
        | draggedBlock = Just newDraggedBlock
        , dragBeacons = Dict.insert newId sidebarPath model.dragBeacons
    }


pickupOnDrag : Model -> DraggedBlock -> LifeBlock -> Model
pickupOnDrag model draggedBlock lifeBlock =
    -- TODO
    -- need to leave a ghost in the original slot, being dropped below yourself does nothing
    -- this is separate from 'split on drag'
    -- have a static 'originSlot' that displays a ghost of draggedBlock
    { model | draggedBlock = Just draggedBlock }


bump : Model -> ( Int, Model )
bump model =
    ( model.nextBeaconId
    , { model | nextBeaconId = model.nextBeaconId + 1 }
    )



-- VIEW


view : Model -> Element Msg
view model =
    row [ width fill, height fill, scrollbarY, spacing 40 ]
        [ viewSidebar model
        , viewMainArea <| lookupBenchBlocks model
        , viewDraggedBlock model.draggedBlock model.dragBeacons
        ]


lookupBenchBlocks : Model -> List LifeBlock
lookupBenchBlocks { dragBeacons, benchBlocks } =
    benchBlocks
        |> List.map (Common.lookup dragBeacons)
        |> List.filterMap identity
        |> List.map dragBlock


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
        , width fill
        ]
        (List.take 4 slots)


viewFragment : LifeBlock -> Element Msg
viewFragment block =
    column [ width <| px 350 ]
        [ Input.button [ alignRight ]
            { onPress = Just <| DeleteLifeBlock block.beaconId
            , label = text "X"
            }
        , viewLifepath block.first { withBeacon = Just block.beaconId }
        ]


openSlot : Element Msg
openSlot =
    el
        (beaconAttribute (staticBeaconId OpenSlot)
            :: Border.width 1
            :: slotAttrs
        )
        (el [ centerX, centerY ] <| text "+")


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
            viewLifepath block.first { withBeacon = Nothing }

        BenchBlock block ->
            viewLifepath block.first { withBeacon = Nothing }


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
                viewLifepath block.first { withBeacon = Just block.beaconId }
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


coordsDecoder : Decode.Decoder Point
coordsDecoder =
    Decode.map2 Point
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)


beaconsDecoder : Decode.Decoder (List ( Int, Box ))
beaconsDecoder =
    Decode.list
        (Decode.map2
            Tuple.pair
            (Decode.field "id" Decode.int)
            boxDecoder
        )


boxDecoder : Decode.Decoder Box
boxDecoder =
    Decode.map4 Box
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)
        (Decode.field "width" Decode.float)
        (Decode.field "height" Decode.float)


closestBoundingBeacon : DragData -> Maybe BeaconBox
closestBoundingBeacon { cursor, beacons } =
    beacons
        |> List.sortBy (Geom.distance cursor << Geom.center << .box)
        |> List.head
        |> Common.keepIf (\beacon -> Geom.bounds beacon.box cursor)
