module Creation exposing (..)

import Api exposing (ApiResult, noFilters)
import Beacons exposing (DragData, HoverState)
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
import Json.Encode as Encode
import LifeBlock exposing (LifeBlock)
import Lifepath exposing (Lead, Lifepath, Skill, StatMod, StatModType(..))
import List.NonEmpty as NonEmpty exposing (NonEmpty)
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
    , dragState : Beacons.DragState
    }


type DragBeacon
    = SidebarPath Lifepath Int
    | BenchBlock LifeBlock


dragBlock : DragBeacon -> LifeBlock
dragBlock beacon =
    -- TODO think about splitting these into two dicts
    case beacon of
        SidebarPath path id ->
            LifeBlock.singleton path id

        BenchBlock block ->
            block


type DropBeacon
    = Static StaticBeacon


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
      , dragState = Beacons.NotDragging
      }
    , fetchLifepaths searchFilters
    )


initialDropBeacons : Dict Int DropBeacon
initialDropBeacons =
    [ OpenSlot ]
        |> List.map (\beacon -> ( staticBeaconId beacon, Static beacon ))
        |> Dict.fromList


{-| Beacons with non-generated beacon ids.
TODO replace this concept with having multiple open slots
make the benchBlocks list into an array
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
    | DragMsg Beacons.Transition
    | DeleteBenchBlock Int
    | EnteredSearchText String
    | SearchTimePassed String
    | ClickedBornCheckbox Bool
    | NoOp


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

                ( newModel, pairs ) =
                    addBatch cleanModel lifepaths SidebarPath
            in
            ( { newModel | sidebarLifepaths = Loaded (List.map Tuple.second pairs) }
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

        DragMsg (Beacons.PickUp draggedItem) ->
            let
                newModel =
                    case Dict.get draggedItem.beaconId model.dragBeacons of
                        Just _ ->
                            { model | dragState = Beacons.Dragging draggedItem }

                        Nothing ->
                            model
            in
            ( newModel, Cmd.none )

        DragMsg (Beacons.DragMove dragState) ->
            ( { model | dragState = dragState }, Cmd.none )

        DragMsg (Beacons.LetGo draggedItem) ->
            ( { model | dragState = Beacons.NotDragging }, Cmd.none )

        DragMsg (Beacons.Drop hoverState) ->
            ( dropDraggedBlock model hoverState, Cmd.none )

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

        DragMsg Beacons.NoOp ->
            -- TODO remove/flatten this
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


deleteBenchBlock : Model -> Int -> Model
deleteBenchBlock model id =
    { model
        | dragBeacons = Dict.remove id model.dragBeacons
        , benchBlocks =
            List.filter (\beaconId -> beaconId /= id) model.benchBlocks
    }


addBatch :
    Model
    -> List Lifepath
    -> (Lifepath -> Int -> DragBeacon)
    -> ( Model, List ( Lifepath, Int ) )
addBatch ({ nextBeaconId, dragBeacons } as model) lifepaths constructor =
    let
        makePair : Lifepath -> ( Int, List ( Lifepath, Int ) ) -> ( Int, List ( Lifepath, Int ) )
        makePair path ( nextId, pairList ) =
            let
                pair =
                    ( path, nextId )
            in
            ( nextId + 1, pair :: pairList )

        ( newNextId, blocksWithIds ) =
            List.foldl makePair ( nextBeaconId, [] ) lifepaths

        insertBlock : ( Lifepath, Int ) -> Dict Int DragBeacon -> Dict Int DragBeacon
        insertBlock ( p, i ) dict =
            Dict.insert i (constructor p i) dict

        newBlocks : Dict Int DragBeacon
        newBlocks =
            List.foldl insertBlock dragBeacons blocksWithIds
    in
    ( { model | nextBeaconId = newNextId, dragBeacons = newBlocks }
    , List.reverse blocksWithIds
    )


dropBeaconIds : Model -> Set Int
dropBeaconIds =
    .dropBeacons >> Dict.keys >> Set.fromList


dropDraggedBlock : Model -> HoverState -> Model
dropDraggedBlock model hoverState =
    case lookupDragAndDrop model hoverState of
        -- TODO handle other kinds of drop
        Just ( SidebarPath path _, Static OpenSlot ) ->
            let
                ( beaconId, bumpedModel ) =
                    bump model

                benchBlock =
                    BenchBlock <| LifeBlock.singleton path beaconId
            in
            { bumpedModel
                | benchBlocks = model.benchBlocks ++ [ beaconId ]
                , dragBeacons = Dict.insert beaconId benchBlock model.dragBeacons
                , dragState = Beacons.NotDragging
            }

        _ ->
            { model | dragState = Beacons.NotDragging }


lookupDragAndDrop : Model -> HoverState -> Maybe ( DragBeacon, DropBeacon )
lookupDragAndDrop model { draggedItem, hoveredDropBeacon } =
    case
        ( Dict.get draggedItem.beaconId model.dragBeacons
        , Dict.get hoveredDropBeacon model.dropBeacons
        )
    of
        ( Just dragBeacon, Just dropBeacon ) ->
            Just ( dragBeacon, dropBeacon )

        _ ->
            Nothing


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


type alias ModelView =
    { session : Session
    , searchFilters : Api.LifepathFilters
    , dragState : DragStateView
    , benchBlocks : List LifeBlock
    , sidebarLifepaths : Status (List ( Lifepath, Int ))
    , draggedLifeBlock : Maybe DraggedLifeBlock
    }


type alias DraggedLifeBlock =
    { lifeBlock : LifeBlock
    , cursorOnScreen : Point
    , cursorOnDraggable : Point
    }


modelView : Model -> Result InvalidModel ModelView
modelView model =
    Result.map4
        (\dragState sidebarLifepaths benchBlocks draggedLifeBlock ->
            { session = model.session
            , searchFilters = model.searchFilters
            , dragState = dragState
            , benchBlocks = benchBlocks
            , sidebarLifepaths = sidebarLifepaths
            , draggedLifeBlock = draggedLifeBlock
            }
        )
        (lookupDragState model)
        (lookupSidebarLifepaths model)
        (lookupBenchBlocks model)
        (lookupDraggedBlock model)


lookupDraggedBlock : Model -> Result InvalidModel (Maybe DraggedLifeBlock)
lookupDraggedBlock model =
    case Beacons.getDraggedItem model.dragState of
        Nothing ->
            Ok Nothing

        Just draggedBlock ->
            case Dict.get draggedBlock.beaconId model.dragBeacons of
                Nothing ->
                    Err <| MissingDragBlock <| draggedBlock.beaconId

                Just beacon ->
                    Ok <|
                        Just <|
                            { lifeBlock = dragBlock beacon
                            , cursorOnScreen = draggedBlock.cursorOnScreen
                            , cursorOnDraggable = draggedBlock.cursorOnDraggable
                            }


type DragStateView
    = NotDraggingView
    | DraggingView DragBeacon
    | HoveringView HoverBeaconsView


type alias HoverBeaconsView =
    { dragBeacon : DragBeacon
    , dropBeacon : DropBeacon
    }


lookupDragState : Model -> Result InvalidModel DragStateView
lookupDragState { dragState, dragBeacons, dropBeacons } =
    -- TODO make this call a Beacons fn that returns a DragState
    -- then match on the DragState to get
    case dragState of
        Beacons.NotDragging ->
            Ok NotDraggingView

        Beacons.Dragging dragBeacon ->
            dragBeacons
                |> Dict.get dragBeacon.beaconId
                |> Maybe.map DraggingView
                |> Result.fromMaybe InvalidDragState

        Beacons.Hovering { draggedItem, hoveredDropBeacon } ->
            case
                ( Dict.get draggedItem.beaconId dragBeacons
                , Dict.get hoveredDropBeacon dropBeacons
                )
            of
                ( Just dragBeacon, Just dropBeacon ) ->
                    Ok <| HoveringView <| HoverBeaconsView dragBeacon dropBeacon

                ( drag, drop ) ->
                    Err InvalidDragState


type InvalidModel
    = InvalidDragState
    | MissingDragBlock Int
    | MissingBenchBlocks (List Int)
    | MissingSidebarPaths (List Int)


view : Model -> Element Msg
view model =
    case modelView model of
        Ok viewedModel ->
            row [ width fill, height fill, scrollbarY, spacing 40 ]
                [ viewSidebar viewedModel
                , viewMainArea
                    viewedModel.benchBlocks
                    (getHoverState viewedModel.dragState)
                , viewDraggedBlock viewedModel.draggedLifeBlock
                ]

        Err err ->
            Debug.todo "display an error message"


getHoverState : DragStateView -> Maybe HoverBeaconsView
getHoverState dragState =
    case dragState of
        HoveringView hover ->
            Just hover

        _ ->
            Nothing


lookupBenchBlocks : Model -> Result InvalidModel (List LifeBlock)
lookupBenchBlocks { dragBeacons, benchBlocks } =
    benchBlocks
        |> Common.lookupAll dragBeacons
        |> Result.map (List.map dragBlock)
        |> Result.mapError
            (\(Common.MissingValues ids) -> MissingBenchBlocks ids)


viewMainArea : List LifeBlock -> Maybe HoverBeaconsView -> Element Msg
viewMainArea fragments hover =
    let
        filledSlots =
            List.map (viewLifeBlock Nothing) fragments ++ [ openSlot hover ]

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


openSlot : Maybe HoverBeaconsView -> Element Msg
openSlot hover =
    let
        beingHovered : Maybe Bool
        beingHovered =
            Maybe.map (\state -> state.dropBeacon == Static OpenSlot) hover

        hoveringBlock : Maybe LifeBlock
        hoveringBlock =
            Maybe.map (.dragBeacon >> dragBlock) hover
    in
    case ( beingHovered, hoveringBlock ) of
        ( Just True, Just block ) ->
            viewLifeBlock (Just <| staticBeaconId OpenSlot) block

        _ ->
            el
                (Beacons.attribute (staticBeaconId OpenSlot)
                    :: Border.width 1
                    :: slotAttrs
                )
                (el [ centerX, centerY ] <| text "+")


viewLifeBlock : Maybe Int -> LifeBlock -> Element Msg
viewLifeBlock maybeBeaconId block =
    LifeBlock.view
        { lifepathWidth = lifepathWidth
        , baseAttrs = slotAttrs
        , dropBeaconId = maybeBeaconId
        , onDelete = Just <| DeleteBenchBlock <| LifeBlock.beaconId block
        }
        block


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


viewDraggedBlock : Maybe DraggedLifeBlock -> Element Msg
viewDraggedBlock maybeBlock =
    let
        top : DraggedLifeBlock -> String
        top { cursorOnScreen, cursorOnDraggable } =
            String.fromFloat (cursorOnScreen.y - cursorOnDraggable.y) ++ "px"

        left : DraggedLifeBlock -> String
        left { cursorOnScreen, cursorOnDraggable } =
            String.fromFloat (cursorOnScreen.x - cursorOnDraggable.x) ++ "px"
    in
    case maybeBlock of
        Just dragged ->
            column
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
                    ++ Common.userSelectNone
                )
            <|
                List.map
                    (\path -> viewLifepath path { withBeacon = Nothing })
                    (NonEmpty.toList <| LifeBlock.paths dragged.lifeBlock)

        _ ->
            none


viewSidebar : ModelView -> Element Msg
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
        , viewSidebarLifepaths model.sidebarLifepaths
        ]


lookupSidebarLifepaths :
    Model
    -> Result InvalidModel (Status (List ( Lifepath, Int )))
lookupSidebarLifepaths { dragBeacons, sidebarLifepaths } =
    case sidebarLifepaths of
        Loading ->
            Ok Loading

        Failed ->
            Ok Failed

        Loaded sidebarIds ->
            let
                lookup : DragBeacon -> Maybe ( Lifepath, Int )
                lookup beacon =
                    case beacon of
                        SidebarPath path id ->
                            Just ( path, id )

                        BenchBlock _ ->
                            Nothing
            in
            sidebarIds
                |> Common.lookupAll dragBeacons
                |> Result.map (Loaded << List.filterMap lookup)
                |> Result.mapError
                    (\(Common.MissingValues ids) -> MissingSidebarPaths ids)


viewSidebarLifepaths : Status (List ( Lifepath, Int )) -> Element Msg
viewSidebarLifepaths sidebarLifepaths =
    let
        viewPair ( p, i ) =
            viewLifepath p { withBeacon = Just i }
    in
    case sidebarLifepaths of
        Loading ->
            text "loading..."

        Failed ->
            text "couldn't load lifepaths"

        Loaded pairs ->
            column [ spacing 20, padding 20, width fill, height fill, scrollbarY ]
                (List.map viewPair pairs)


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


viewLifepath : Lifepath -> { withBeacon : Maybe Int } -> Element msg
viewLifepath =
    Lifepath.view lifepathWidth


lifepathWidth : Length
lifepathWidth =
    px 300



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map DragMsg <|
        Beacons.subscriptions (dropBeaconIds model) model.dragState
