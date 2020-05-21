module Creation exposing (..)

import Api exposing (ApiResult, noFilters)
import Array exposing (Array)
import Beacon exposing (DragData, HoverState)
import Colors exposing (..)
import Common
import Creation.BeaconId as BeaconId exposing (DragBeaconId, DropBeaconId)
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
    , searchFilters : Api.LifepathFilters
    , sidebarLifepaths : Status (Array Lifepath)
    , benchBlocks : Array LifeBlock
    , dragState : Beacon.DragState DragBeaconId DropBeaconId
    , dragCache : Maybe LifeBlock
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
      , searchFilters = searchFilters
      , sidebarLifepaths = Loading
      , benchBlocks = Array.empty
      , dragState = Beacon.NotDragging
      , dragCache = Nothing
      }
    , fetchLifepaths searchFilters
    )


fetchLifepaths : Api.LifepathFilters -> Cmd Msg
fetchLifepaths searchFilters =
    Api.listLifepaths GotLifepaths searchFilters



-- UPDATE


type Msg
    = GotLifepaths (ApiResult (List Lifepath))
    | DragMsg (Beacon.Transition DragBeaconId DropBeaconId)
    | DeleteBenchBlock DragBeaconId
    | EnteredSearchText String
    | SearchTimePassed String
    | ClickedBornCheckbox Bool
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotLifepaths (Ok lifepaths) ->
            ( { model | sidebarLifepaths = Loaded <| Array.fromList lifepaths }
            , Cmd.none
            )

        GotLifepaths (Err error) ->
            ( { model | sidebarLifepaths = Failed }
            , Cmd.none
            )

        DragMsg (Beacon.PickUp draggedItem) ->
            ( pickup model draggedItem, Cmd.none )

        DragMsg (Beacon.DragMove dragState) ->
            ( { model | dragState = dragState }, Cmd.none )

        DragMsg (Beacon.LetGo draggedItem) ->
            ( { model | dragState = Beacon.NotDragging }, Cmd.none )

        DragMsg (Beacon.Drop hoverState) ->
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

        DragMsg Beacon.NoOp ->
            -- TODO remove/flatten this
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


deleteBenchBlock : Model -> DragBeaconId -> Model
deleteBenchBlock model id =
    { model
        | benchBlocks =
            Array.filter (\block -> LifeBlock.beaconId block /= id) model.benchBlocks
        , dragCache = Nothing
    }


pickup : Model -> Beacon.DraggedItem DragBeaconId -> Model
pickup model draggedItem =
    case lookupDragged model draggedItem.beaconId of
        Just lifeblock ->
            { model
                | dragState = Beacon.Dragging draggedItem
                , dragCache = Just lifeblock
            }

        Nothing ->
            Debug.todo "this in an error case"


dropDraggedBlock : Model -> HoverState DragBeaconId DropBeaconId -> Model
dropDraggedBlock model hoverState =
    -- TODO handle other kinds of drop
    -- this assumes that we're over the open slot
    case lookupDragged model hoverState.draggedItem.beaconId of
        Just lifeblock ->
            { model
                | benchBlocks = Array.push lifeblock model.benchBlocks
                , dragState = Beacon.NotDragging
                , dragCache = Nothing
            }

        _ ->
            -- TODO this is an error state
            { model | dragState = Beacon.NotDragging, dragCache = Nothing }


{-| Look up a lifeblock in the model by its drag id (aka its original location).
Returning nothing signifies an error.
-}
lookupDragged : Model -> DragBeaconId -> Maybe LifeBlock
lookupDragged { benchBlocks, sidebarLifepaths, dragCache } dragId =
    if Just dragId == Maybe.map LifeBlock.beaconId dragCache then
        dragCache

    else
        case BeaconId.dragLocation dragId of
            BeaconId.Bench { benchIndex, blockIndex } ->
                -- TODO split the block
                Array.get benchIndex benchBlocks

            BeaconId.Sidebar sidebarIndex ->
                case sidebarLifepaths of
                    Loaded paths ->
                        Array.get sidebarIndex paths
                            |> Maybe.map (\path -> LifeBlock.singleton path dragId)

                    _ ->
                        Nothing


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



-- VIEW


{-| TODO can this be removed now?
-}
type alias ModelView =
    { session : Session
    , searchFilters : Api.LifepathFilters
    , dragState : DragStateView
    , benchBlocks : Array LifeBlock
    , sidebarLifepaths : Status (Array Lifepath)
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
        (Ok <| model.sidebarLifepaths)
        (Ok <| model.benchBlocks)
        (lookupDraggedBlock model)


lookupDraggedBlock : Model -> Result InvalidModel (Maybe DraggedLifeBlock)
lookupDraggedBlock model =
    let
        validate : Beacon.DraggedItem DragBeaconId -> LifeBlock -> Result InvalidModel (Maybe DraggedLifeBlock)
        validate draggedItem block =
            if draggedItem.beaconId == LifeBlock.beaconId block then
                Ok <| Just <| DraggedLifeBlock block draggedItem.cursorOnScreen draggedItem.cursorOnDraggable

            else
                Err InvalidDragState
    in
    case ( model.dragState, model.dragCache ) of
        ( Beacon.NotDragging, _ ) ->
            Ok Nothing

        ( Beacon.Dragging draggedItem, Just block ) ->
            validate draggedItem block

        ( Beacon.Hovering { draggedItem }, Just block ) ->
            validate draggedItem block

        _ ->
            Err InvalidDragState


type DragStateView
    = NotDraggingView
    | DraggingView LifeBlock
    | HoveringView HoverBeaconsView


type alias HoverBeaconsView =
    { dragBeacon : LifeBlock

    -- TODO keep data of where the drop is here
    , dropBeacon : ()
    }


lookupDragState : Model -> Result InvalidModel DragStateView
lookupDragState { dragState, dragCache } =
    -- TODO this just trusts the cache; factor out/reuse the validate function
    -- or just delete the whole modelview thing
    case ( dragState, dragCache ) of
        ( Beacon.NotDragging, _ ) ->
            Ok NotDraggingView

        ( Beacon.Dragging _, Just cached ) ->
            Ok <| DraggingView cached

        ( Beacon.Hovering _, Just cached ) ->
            Ok <| HoveringView { dragBeacon = cached, dropBeacon = () }

        _ ->
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


viewMainArea : Array LifeBlock -> Maybe HoverBeaconsView -> Element Msg
viewMainArea fragments hover =
    let
        filledSlots =
            Array.push (openSlot hover) <| Array.map (viewLifeBlock Nothing) fragments

        slots =
            Array.toList filledSlots
                ++ List.repeat
                    (8 - Array.length filledSlots)
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
        beingHovered : Bool
        beingHovered =
            -- TODO actually check the drop beacon
            Maybe.map (\state -> state.dropBeacon == ()) hover
                |> Maybe.withDefault False

        hoveringBlock : Maybe LifeBlock
        hoveringBlock =
            Maybe.map .dragBeacon hover
    in
    case ( beingHovered, hoveringBlock ) of
        ( True, Just block ) ->
            viewLifeBlock (Just <| BeaconId.staticOpenSlot) block

        _ ->
            el
                (BeaconId.dropAttribute BeaconId.staticOpenSlot
                    :: Border.width 1
                    :: slotAttrs
                )
                (el [ centerX, centerY ] <| text "+")


viewLifeBlock : Maybe DropBeaconId -> LifeBlock -> Element Msg
viewLifeBlock dropBeaconId block =
    LifeBlock.view
        { baseAttrs = slotAttrs
        , dropBeaconId = dropBeaconId
        , onDelete = Just <| DeleteBenchBlock <| LifeBlock.beaconId block
        }
        block


{-| Attributes common to open and filled slots on the bench
-}
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


{-| Displays the hovering block at the users cursor
TODO should this be in LifeBlock?
-}
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
                 , width Lifepath.lifepathWidth
                 ]
                    ++ Common.userSelectNone
                )
            <|
                List.map
                    (\path -> Lifepath.view path { withBeacon = Nothing })
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


viewSidebarLifepaths : Status (Array Lifepath) -> Element Msg
viewSidebarLifepaths sidebarLifepaths =
    let
        viewPath : Int -> Lifepath -> Element Msg
        viewPath i path =
            let
                id =
                    BeaconId.dragBeaconId <| BeaconId.Sidebar i
            in
            Lifepath.view path { withBeacon = Just id }
    in
    case sidebarLifepaths of
        Loading ->
            text "loading..."

        Failed ->
            text "couldn't load lifepaths"

        Loaded paths ->
            column [ spacing 20, padding 20, width fill, height fill, scrollbarY ]
                (Array.toList <| Array.indexedMap viewPath paths)


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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map DragMsg <|
        Beacon.subscriptions
            BeaconId.dragIdFromInt
            BeaconId.dropIdFromInt
            model.dragState
