module Creation exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Api
import Array exposing (Array)
import Colors
import Creation.BeaconId as BeaconId
    exposing
        ( BenchIndex
        , DragBeaconId
        , DropBeaconId
        , HoverBeaconId
        , dragLocation
        )
import Creation.LifepathFilter as LifepathFilter exposing (LifepathFilter)
import Creation.Status as Status exposing (Status)
import Creation.Workbench as Workbench exposing (Workbench)
import DragState
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Http
import LifeBlock exposing (LifeBlock)
import LifeBlock.Validation as Validation
import Lifepath exposing (Lifepath, StatModType(..))
import List.NonEmpty exposing (NonEmpty)
import Process
import Session exposing (..)
import Task



-- MODEL


type alias Model =
    { session : Session
    , searchFilter : LifepathFilter
    , sidebarLifepaths : Status LoadedLifepaths
    , workbench : Workbench
    , dragState : DragState
    }


type alias LoadedLifepaths =
    { all : Array Lifepath
    , sidebar : Array Lifepath
    }


{-| DragState as used by this page.
-}
type alias DragState =
    DragState.DragState DragBeaconId DropBeaconId HoverBeaconId DragCache


{-| The dragged block, and the workbench
as it will look once the dragged block is removed.
-}
type alias DragCache =
    ( Workbench, LifeBlock )


type InvalidModel
    = InvalidDragState
    | BoundsError


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , searchFilter = LifepathFilter.none
      , sidebarLifepaths = Status.Loading
      , workbench = Workbench.default
      , dragState = DragState.None
      }
    , fetchDwarves
    )


fetchDwarves : Cmd Msg
fetchDwarves =
    Api.dwarves GotDwarves



-- UPDATE


type Msg
    = GotDwarves (Result Http.Error (List Lifepath))
    | DragMsg Transition
    | DeleteBenchBlock BenchIndex
    | EnteredSearchText String
    | SearchTimePassed String
    | SetFit LifeBlock.Fit
    | ClearFit


{-| DragState.Transition as used by this page.
-}
type alias Transition =
    DragState.Transition DragBeaconId DropBeaconId HoverBeaconId DragCache


type alias DraggedItem =
    DragState.DraggedItem DragBeaconId


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDwarves (Ok lifepaths) ->
            let
                all =
                    Array.fromList lifepaths

                sidebarLifepaths =
                    Status.Loaded { all = all, sidebar = all }
            in
            ( { model | sidebarLifepaths = sidebarLifepaths }
            , Cmd.none
            )

        GotDwarves (Err _) ->
            ( { model | sidebarLifepaths = Status.Failed }
            , Cmd.none
            )

        DragMsg (DragState.PickUp draggedItem) ->
            case pickup model draggedItem of
                Ok newModel ->
                    ( newModel, Cmd.none )

                Err err ->
                    giveUp model "Error during pick up" err

        DragMsg (DragState.Carry dragState) ->
            ( { model | dragState = dragState }, Cmd.none )

        DragMsg DragState.LetGo ->
            ( letGo model, Cmd.none )

        DragMsg DragState.Drop ->
            case drop model of
                Ok newModel ->
                    ( newModel, Cmd.none )

                Err err ->
                    giveUp model "Error during drop" err

        DragMsg (DragState.BeginHover hoverId) ->
            ( { model | dragState = DragState.Hovered hoverId }
            , Cmd.none
            )

        DragMsg DragState.EndHover ->
            ( letGo model, Cmd.none )

        DeleteBenchBlock benchIndex ->
            ( { model | workbench = Workbench.deleteBlock model.workbench benchIndex }
            , Cmd.none
            )

        SetFit fit ->
            let
                searchFilter =
                    LifepathFilter.withFit (Just fit) model.searchFilter
            in
            ( filterLifepaths { model | searchFilter = searchFilter }
            , Cmd.none
            )

        ClearFit ->
            let
                searchFilter =
                    LifepathFilter.withFit Nothing model.searchFilter
            in
            ( filterLifepaths { model | searchFilter = searchFilter }
            , Cmd.none
            )

        EnteredSearchText input ->
            let
                searchFilter =
                    LifepathFilter.withSearchTerm input model.searchFilter
            in
            ( { model | searchFilter = searchFilter }
            , beginSearchDebounce input
            )

        SearchTimePassed searchTerm ->
            ( searchTimePassed model searchTerm
            , Cmd.none
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
    { model | dragState = DragState.None }


pickup : Model -> DragState.DraggedItem DragBeaconId -> Result InvalidModel Model
pickup model draggedItem =
    let
        beginDragging : DragCache -> Model
        beginDragging cache =
            { model | dragState = DragState.Dragged ( draggedItem, cache ) }
    in
    pickupDragBeacon model draggedItem.beaconId
        |> Result.map beginDragging


pickupDragBeacon : Model -> DragBeaconId -> Result InvalidModel DragCache
pickupDragBeacon { workbench, sidebarLifepaths } dragId =
    case BeaconId.dragLocation dragId of
        BeaconId.Bench location ->
            Workbench.pickup workbench location
                |> Result.mapError pickupError

        BeaconId.Sidebar sidebarIndex ->
            case sidebarLifepaths of
                Status.Loaded { sidebar } ->
                    Array.get sidebarIndex sidebar
                        |> Maybe.map (\path -> ( workbench, LifeBlock.singleton path ))
                        |> Result.fromMaybe BoundsError

                _ ->
                    Err InvalidDragState


pickupError : Workbench.PickupError -> InvalidModel
pickupError err =
    case err of
        Workbench.PickupBoundsError ->
            BoundsError

        Workbench.NoLifeBlock ->
            InvalidDragState


drop : Model -> Result InvalidModel Model
drop model =
    case model.dragState of
        DragState.Poised ( hoverState, ( cachedBench, cachedBlock ) ) ->
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
                    Ok { model | workbench = workbench, dragState = DragState.None }

        DragState.Dragged _ ->
            Ok <| letGo model

        DragState.Hovered _ ->
            Err InvalidDragState

        DragState.None ->
            Err InvalidDragState


searchTimePassed : Model -> String -> Model
searchTimePassed model oldInput =
    if model.searchFilter.searchTerm == oldInput then
        filterLifepaths model

    else
        model


filterLifepaths : Model -> Model
filterLifepaths model =
    let
        applyFilter : LoadedLifepaths -> LoadedLifepaths
        applyFilter { all } =
            { all = all
            , sidebar = LifepathFilter.apply model.searchFilter all
            }
    in
    { model | sidebarLifepaths = Status.map applyFilter model.sidebarLifepaths }


beginSearchDebounce : String -> Cmd Msg
beginSearchDebounce input =
    Process.sleep 250
        |> Task.perform (\_ -> SearchTimePassed input)



-- VIEW


view : Model -> Element Msg
view model =
    let
        viewPage : { workbench : Element Msg, draggedBlock : Element Msg } -> Element Msg
        viewPage { workbench, draggedBlock } =
            row [ width fill, height fill, scrollbarY, spacing 40 ]
                [ viewSidebar model
                , workbench
                , draggedBlock
                ]

        viewBench : Workbench.Hover -> Element Msg
        viewBench hover =
            Workbench.view model.workbench
                { hover = hover
                , deleteBenchBlock = DeleteBenchBlock
                , filterPressed = SetFit
                }
    in
    case model.dragState of
        DragState.None ->
            viewPage { workbench = viewBench Workbench.None, draggedBlock = none }

        DragState.Hovered id ->
            viewPage
                { workbench = viewBench <| Workbench.Empty <| BeaconId.hoverLocation id
                , draggedBlock = none
                }

        DragState.Dragged ( draggedItem, ( _, cachedBlock ) ) ->
            viewPage
                -- TODO this needs a new state
                { workbench = viewBench <| Workbench.Carry cachedBlock
                , draggedBlock = viewDraggedBlock draggedItem cachedBlock Nothing
                }

        DragState.Poised ( { draggedItem, hoveredDropBeacon }, ( cachedBench, cachedBlock ) ) ->
            let
                dropAttempt : Result Workbench.DropError Workbench
                dropAttempt =
                    Workbench.drop cachedBench cachedBlock <| BeaconId.dropLocation hoveredDropBeacon

                hover : Maybe Bool -> Workbench.Hover
                hover dropHighlight =
                    Workbench.Full
                        { hoveringBlock = cachedBlock
                        , dropLocation = BeaconId.dropLocation hoveredDropBeacon
                        , dropHighlight = dropHighlight
                        }
            in
            case dropAttempt of
                Ok _ ->
                    viewPage
                        { workbench = viewBench <| hover <| Just True
                        , draggedBlock = viewDraggedBlock draggedItem cachedBlock Nothing
                        }

                Err (Workbench.CombinationError errs) ->
                    viewPage
                        { workbench = viewBench <| hover <| Just False
                        , draggedBlock = viewDraggedBlock draggedItem cachedBlock <| Just errs
                        }

                Err err ->
                    let
                        _ =
                            Debug.log "error during hypothetical drop" err
                    in
                    viewPage
                        { workbench = viewBench <| hover Nothing
                        , draggedBlock = viewDraggedBlock draggedItem cachedBlock Nothing
                        }


viewDraggedBlock : DraggedItem -> LifeBlock -> Maybe (NonEmpty Validation.Error) -> Element Msg
viewDraggedBlock { cursorOnScreen, cursorOnDraggable } draggedBlock errors =
    Workbench.viewDraggedBlock draggedBlock
        { top = cursorOnScreen.y - cursorOnDraggable.y
        , left = cursorOnScreen.x - cursorOnDraggable.x
        , errors = errors
        }


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
        [ LifepathFilter.view
            { enteredSearchText = EnteredSearchText
            }
            model.searchFilter
        , viewSidebarLifepaths model.sidebarLifepaths
        ]


viewSidebarLifepaths : Status LoadedLifepaths -> Element Msg
viewSidebarLifepaths sidebarLifepaths =
    let
        viewPath : Int -> Lifepath -> Element Msg
        viewPath index =
            Lifepath.view { withBeacon = Just <| BeaconId.sidebarDragId index }
    in
    case sidebarLifepaths of
        Status.Loading ->
            text "loading..."

        Status.Failed ->
            text "couldn't load lifepaths"

        Status.Loaded { sidebar } ->
            column [ spacing 20, padding 20, width fill, height fill, scrollbarY ] <|
                List.indexedMap viewPath <|
                    Array.toList sidebar



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    model.dragState
        |> DragState.subscriptions
            { toDragId = BeaconId.dragIdFromInt
            , toDropId = BeaconId.dropIdFromInt
            , toHoverId = BeaconId.hoverIdFromInt
            }
        |> Sub.map DragMsg
