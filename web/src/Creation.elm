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
import Creation.BeaconId as BeaconId
    exposing
        ( BenchIndex
        , DragBeaconId
        , DropBeaconId
        , HoverBeaconId
        , dragLocation
        )
import Creation.Workbench as Workbench exposing (Workbench)
import DragState exposing (DragState)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Geom exposing (Point)
import LifeBlock exposing (LifeBlock)
import Lifepath exposing (Lifepath, StatModType(..))
import Process
import Session exposing (..)
import Task



-- MODEL


type alias Model =
    { session : Session
    , searchFilter : LifepathFilter
    , sidebarLifepaths : Status (Array Lifepath)
    , workbench : Workbench
    , dragState : DragState DragBeaconId DropBeaconId HoverBeaconId DragCache
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


type InvalidModel
    = InvalidDragState
    | BoundsError


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , searchFilter = LifepathFilter.default
      , sidebarLifepaths = Loading
      , workbench = Workbench.default
      , dragState = DragState.None
      }
    , fetchLifepaths LifepathFilter.default
    )


fetchLifepaths : LifepathFilter -> Cmd Msg
fetchLifepaths searchFilter =
    Api.listLifepaths GotLifepaths searchFilter



-- UPDATE


type Msg
    = GotLifepaths (ApiResult (List Lifepath))
    | DragMsg (DragState.Transition DragBeaconId DropBeaconId HoverBeaconId DragCache)
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

        DragMsg DragState.LetGo ->
            ( letGo model, Cmd.none )

        DragMsg DragState.Drop ->
            case drop model of
                Ok newModel ->
                    ( newModel, Cmd.none )

                Err err ->
                    giveUp model "Error during drop" err

        DragMsg (DragState.BeginHover hoverId) ->
            ( { model | dragState = DragState.EmptyHover hoverId }
            , Cmd.none
            )

        DragMsg DragState.EndHover ->
            ( letGo model, Cmd.none )

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
    { model | dragState = DragState.None }


pickup : Model -> DragState.DraggedItem DragBeaconId -> Result InvalidModel Model
pickup model draggedItem =
    let
        beginDragging : DragCache -> Model
        beginDragging cache =
            { model | dragState = DragState.Dragging ( draggedItem, cache ) }
    in
    pickupDragBeacon model draggedItem.beaconId
        |> Result.map beginDragging


pickupDragBeacon : Model -> DragBeaconId -> Result InvalidModel DragCache
pickupDragBeacon { workbench, sidebarLifepaths } dragId =
    case BeaconId.dragLocation dragId of
        BeaconId.Bench loc ->
            Workbench.pickup workbench loc
                |> Result.mapError pickupError

        BeaconId.Sidebar sidebarIndex ->
            case sidebarLifepaths of
                Loaded paths ->
                    Array.get sidebarIndex paths
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
        DragState.Hovering ( hoverState, ( cachedBench, cachedBlock ) ) ->
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

        DragState.Dragging _ ->
            Ok <| letGo model

        DragState.EmptyHover _ ->
            Err InvalidDragState

        DragState.None ->
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


type alias DraggedLifeBlock =
    { lifeBlock : LifeBlock
    , cursorOnScreen : Point
    , cursorOnDraggable : Point
    }


view : Model -> Element Msg
view model =
    row [ width fill, height fill, scrollbarY, spacing 40 ]
        [ viewSidebar model
        , Workbench.view model.workbench
            { hover = benchHover model
            , deleteBenchBlock = DeleteBenchBlock
            }
        , viewDraggedBlock <| lookupDraggedBlock model
        ]


benchHover : Model -> Workbench.Hover
benchHover { dragState } =
    case dragState of
        DragState.None ->
            Workbench.None

        DragState.Dragging _ ->
            Workbench.None

        DragState.EmptyHover id ->
            Workbench.Empty <| BeaconId.hoverLocation id

        DragState.Hovering ( { hoveredDropBeacon }, ( _, cachedBlock ) ) ->
            Workbench.Full
                { hoveringBlock = cachedBlock
                , dropLocation = BeaconId.dropLocation hoveredDropBeacon
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
        DragState.None ->
            Nothing

        DragState.EmptyHover _ ->
            Nothing

        DragState.Dragging ( draggedItem, ( _, cachedBlock ) ) ->
            Just <| draggedLifeBlock draggedItem cachedBlock

        DragState.Hovering ( { draggedItem }, ( _, cachedBlock ) ) ->
            Just <| draggedLifeBlock draggedItem cachedBlock


{-| Displays the hovering block at the users cursor
-}
viewDraggedBlock : Maybe DraggedLifeBlock -> Element Msg
viewDraggedBlock maybeBlock =
    case maybeBlock of
        Just { lifeBlock, cursorOnScreen, cursorOnDraggable } ->
            Workbench.viewDraggedBlock lifeBlock <|
                { top = cursorOnScreen.y - cursorOnDraggable.y
                , left = cursorOnScreen.x - cursorOnDraggable.x
                }

        Nothing ->
            none


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
            , clickedBornCheckbox = ClickedBornCheckbox
            }
            model.searchFilter
        , viewSidebarLifepaths model.sidebarLifepaths
        ]


viewSidebarLifepaths : Status (Array Lifepath) -> Element Msg
viewSidebarLifepaths sidebarLifepaths =
    let
        viewPath : Int -> Lifepath -> Element Msg
        viewPath index =
            Lifepath.view { withBeacon = Just <| BeaconId.sidebarDragId index }
    in
    case sidebarLifepaths of
        Loading ->
            text "loading..."

        Failed ->
            text "couldn't load lifepaths"

        Loaded paths ->
            column [ spacing 20, padding 20, width fill, height fill, scrollbarY ] <|
                List.indexedMap viewPath <|
                    Array.toList paths



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map DragMsg <|
        DragState.subscriptions
            BeaconId.dragIdFromInt
            BeaconId.dropIdFromInt
            BeaconId.hoverIdFromInt
            model.dragState
