module Creation exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Api exposing (ApiResult)
import Api.LifepathFilter as LifepathFilter exposing (LifepathFilter)
import Array exposing (Array)
import Colors
import Common
import Creation.BeaconId as BeaconId
    exposing
        ( BenchIndex
        , DragBeaconId
        , DropBeaconId
        , dragLocation
        )
import Creation.Workbench as Workbench exposing (Workbench)
import DragState exposing (DragState)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Geom exposing (Point)
import Html.Attributes
import LifeBlock exposing (LifeBlock)
import Lifepath exposing (Lifepath, StatModType(..))
import List.NonEmpty as NonEmpty
import Process
import Session exposing (..)
import Task



-- MODEL


type alias Model =
    { session : Session
    , searchFilter : LifepathFilter
    , sidebarLifepaths : Status (Array Lifepath)
    , workbench : Workbench
    , dragState : DragState DragBeaconId DropBeaconId DragCache
    }


{-| The dragged block, and the workbench
as it will look once the dragged block is removed.
-}
type alias DragCache =
    ( Workbench, LifeBlock )


type Status a
    = Loading
    | Loaded a
    | Failed


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , searchFilter = LifepathFilter.default
      , sidebarLifepaths = Loading
      , workbench = Workbench.default
      , dragState = DragState.NotDragging
      }
    , fetchLifepaths LifepathFilter.default
    )


fetchLifepaths : LifepathFilter -> Cmd Msg
fetchLifepaths searchFilter =
    Api.listLifepaths GotLifepaths searchFilter



-- UPDATE


type Msg
    = GotLifepaths (ApiResult (List Lifepath))
    | DragMsg (DragState.Transition DragBeaconId DropBeaconId DragCache)
    | DeleteBenchBlock BenchIndex
    | EnteredSearchText String
    | SearchTimePassed String
    | ClickedBornCheckbox Bool


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotLifepaths (Ok lifepaths) ->
            ( { model | sidebarLifepaths = Loaded <| Array.fromList lifepaths }
            , Cmd.none
            )

        GotLifepaths (Err _) ->
            ( { model | sidebarLifepaths = Failed }
            , Cmd.none
            )

        DragMsg (DragState.PickUp draggedItem) ->
            case pickup model draggedItem of
                Ok newModel ->
                    ( newModel, Cmd.none )

                Err err ->
                    giveUp model "Error during pick up" err

        DragMsg (DragState.DragMove dragState) ->
            ( { model | dragState = dragState }, Cmd.none )

        DragMsg (DragState.LetGo _) ->
            ( letGo model, Cmd.none )

        DragMsg (DragState.Drop hoverState) ->
            case drop model hoverState of
                Ok newModel ->
                    ( newModel, Cmd.none )

                Err err ->
                    giveUp model "Error during drop" err

        DeleteBenchBlock benchIndex ->
            ( { model | workbench = Workbench.deleteBlock model.workbench benchIndex }
            , Cmd.none
            )

        EnteredSearchText input ->
            let
                searchFilter =
                    LifepathFilter.withSearchTerm searchTerm model.searchFilter

                searchTerm =
                    if String.length input > 0 then
                        Just input

                    else
                        Nothing
            in
            ( { model | searchFilter = searchFilter }
            , beginSearchDebounce input
            )

        SearchTimePassed searchTerm ->
            ( model
            , maybeSearch searchTerm model.searchFilter
            )

        ClickedBornCheckbox checked ->
            let
                born =
                    if checked then
                        Just True

                    else
                        Nothing

                searchFilter =
                    LifepathFilter.withBorn born model.searchFilter
            in
            ( { model | searchFilter = searchFilter }
            , fetchLifepaths searchFilter
            )

        DragMsg DragState.NoOp ->
            ( model, Cmd.none )


giveUp : Model -> String -> a -> ( Model, Cmd msg )
giveUp model msg err =
    let
        _ =
            Debug.log msg err
    in
    ( letGo model, Cmd.none )


letGo : Model -> Model
letGo model =
    { model | dragState = DragState.NotDragging }


pickup : Model -> DragState.DraggedItem DragBeaconId -> Result InvalidModel Model
pickup model draggedItem =
    let
        beginDragging : DragCache -> Model
        beginDragging cache =
            { model | dragState = DragState.Dragging ( draggedItem, cache ) }
    in
    pickupDragBeacon model draggedItem.beaconId
        |> Result.map beginDragging


pickupDragBeacon : Model -> DragBeaconId -> Result InvalidModel ( Workbench, LifeBlock )
pickupDragBeacon { workbench, sidebarLifepaths } dragId =
    case BeaconId.dragLocation dragId of
        BeaconId.Bench loc ->
            Workbench.pickup workbench loc
                |> Result.mapError pickupError

        BeaconId.Sidebar sidebarIndex ->
            case sidebarLifepaths of
                Loaded paths ->
                    Array.get sidebarIndex paths
                        |> Maybe.map LifeBlock.singleton
                        |> Result.fromMaybe BoundsError
                        |> Result.map (\block -> ( workbench, block ))

                _ ->
                    Err InvalidDragState


pickupError : Workbench.PickupError -> InvalidModel
pickupError err =
    case err of
        Workbench.PickupBoundsError ->
            BoundsError

        Workbench.NoLifeBlock ->
            InvalidDragState


drop :
    Model
    -> DragState.HoverState DragBeaconId DropBeaconId
    -> Result InvalidModel Model
drop model hoverState =
    case model.dragState of
        DragState.Hovering ( _, ( cachedBench, cachedBlock ) ) ->
            let
                location : BeaconId.DropBeaconLocation
                location =
                    BeaconId.dropLocation hoverState.hoveredDropBeacon
            in
            case Workbench.drop cachedBench cachedBlock location of
                Err (Workbench.CombinationError _) ->
                    Ok <| letGo model

                Err Workbench.DropBoundsError ->
                    Err BoundsError

                Err Workbench.InvalidDropLocation ->
                    Err InvalidDragState

                Ok workbench ->
                    Ok
                        { model
                            | workbench = workbench
                            , dragState = DragState.NotDragging
                        }

        DragState.Dragging _ ->
            Ok <| letGo model

        DragState.NotDragging ->
            Err InvalidDragState


maybeSearch : String -> LifepathFilter -> Cmd Msg
maybeSearch oldInput searchFilter =
    let
        shouldSearch val =
            String.length val >= 2 && val == oldInput
    in
    if Maybe.map shouldSearch searchFilter.searchTerm == Just True then
        fetchLifepaths searchFilter

    else
        Cmd.none


beginSearchDebounce : String -> Cmd Msg
beginSearchDebounce input =
    Process.sleep 500
        |> Task.perform (\_ -> SearchTimePassed input)



-- VIEW


type alias ModelView =
    { session : Session
    , searchFilter : LifepathFilter
    , dragState : DragStateView
    , workbench : Workbench
    , sidebarLifepaths : Status (Array Lifepath)
    , draggedLifeBlock : Maybe DraggedLifeBlock
    }


type alias DraggedLifeBlock =
    { lifeBlock : LifeBlock
    , cursorOnScreen : Point
    , cursorOnDraggable : Point
    }


modelView : Model -> ModelView
modelView model =
    { session = model.session
    , searchFilter = model.searchFilter
    , dragState = lookupDragState model
    , workbench = model.workbench
    , sidebarLifepaths = model.sidebarLifepaths
    , draggedLifeBlock = lookupDraggedBlock model
    }


lookupDraggedBlock : Model -> Maybe DraggedLifeBlock
lookupDraggedBlock model =
    let
        draggedLifeBlock :
            DragState.DraggedItem DragBeaconId
            -> LifeBlock
            -> DraggedLifeBlock
        draggedLifeBlock draggedItem lifeBlock =
            { lifeBlock = lifeBlock
            , cursorOnScreen = draggedItem.cursorOnScreen
            , cursorOnDraggable = draggedItem.cursorOnDraggable
            }
    in
    case model.dragState of
        DragState.NotDragging ->
            Nothing

        DragState.Dragging ( draggedItem, ( _, cachedBlock ) ) ->
            Just <| draggedLifeBlock draggedItem cachedBlock

        DragState.Hovering ( { draggedItem }, ( _, cachedBlock ) ) ->
            Just <| draggedLifeBlock draggedItem cachedBlock


type DragStateView
    = NotDraggingView
    | DraggingView LifeBlock
    | HoveringView Workbench.Hover


lookupDragState : Model -> DragStateView
lookupDragState { dragState } =
    case dragState of
        DragState.NotDragging ->
            NotDraggingView

        DragState.Dragging ( _, ( _, cachedBlock ) ) ->
            DraggingView cachedBlock

        DragState.Hovering ( { hoveredDropBeacon }, ( _, cachedBlock ) ) ->
            HoveringView
                { hoveringBlock = cachedBlock
                , dropLocation = BeaconId.dropLocation hoveredDropBeacon
                }


type InvalidModel
    = InvalidDragState
    | BoundsError


view : Model -> Element Msg
view model =
    let
        benchHover : DragStateView -> Maybe Workbench.Hover
        benchHover dragState =
            case dragState of
                HoveringView hover ->
                    Just hover

                _ ->
                    Nothing

        viewedModel =
            modelView model
    in
    row [ width fill, height fill, scrollbarY, spacing 40 ]
        [ viewSidebar viewedModel
        , Workbench.view
            viewedModel.workbench
            { hover = benchHover viewedModel.dragState
            , deleteBenchBlock = DeleteBenchBlock
            }
        , viewDraggedBlock viewedModel.draggedLifeBlock
        ]


{-| Displays the hovering block at the users cursor
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
                -- TODO move this to LifeBlock module
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
        [ LifepathFilter.view
            { enteredSearchText = EnteredSearchText
            , clickedBornCheckbox = ClickedBornCheckbox
            }
            model.searchFilter
        , viewSidebarLifepaths model.sidebarLifepaths
        ]


viewSidebarLifepaths : Status (Array Lifepath) -> Element Msg
viewSidebarLifepaths sidebarLifepaths =
    let
        viewPath : Int -> Lifepath -> Element Msg
        viewPath i path =
            let
                id =
                    BeaconId.sidebarDragId i
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map DragMsg <|
        DragState.subscriptions
            BeaconId.dragIdFromInt
            BeaconId.dropIdFromInt
            model.dragState
