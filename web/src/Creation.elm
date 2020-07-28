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
import Beacon exposing (HoverState)
import Colors
import Common
import Creation.BeaconId as BeaconId exposing (DragBeaconId, DropBeaconId)
import Creation.Workbench as Workbench exposing (Workbench)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
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
    , benchBlocks : Array (Maybe LifeBlock)
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
        searchFilter : LifepathFilter
        searchFilter =
            LifepathFilter.default
    in
    ( { session = session
      , searchFilter = searchFilter
      , sidebarLifepaths = Loading
      , benchBlocks = Array.repeat 4 Nothing
      , dragState = Beacon.NotDragging
      , dragCache = Nothing
      }
    , fetchLifepaths searchFilter
    )


fetchLifepaths : LifepathFilter -> Cmd Msg
fetchLifepaths searchFilter =
    Api.listLifepaths GotLifepaths searchFilter



-- UPDATE


type Msg
    = GotLifepaths (ApiResult (List Lifepath))
    | DragMsg (Beacon.Transition DragBeaconId DropBeaconId)
    | DeleteBenchBlock Int
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

        GotLifepaths (Err _) ->
            ( { model | sidebarLifepaths = Failed }
            , Cmd.none
            )

        DragMsg (Beacon.PickUp draggedItem) ->
            ( pickup model draggedItem, Cmd.none )

        DragMsg (Beacon.DragMove dragState) ->
            ( { model | dragState = dragState }, Cmd.none )

        DragMsg (Beacon.LetGo _) ->
            ( letGo model, Cmd.none )

        DragMsg (Beacon.Drop hoverState) ->
            case dropDraggedBlock model hoverState of
                Ok newModel ->
                    ( newModel, Cmd.none )

                Err _ ->
                    Debug.todo "display an error or something"

        DeleteBenchBlock benchIndex ->
            ( deleteBenchBlock model benchIndex, Cmd.none )

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

        DragMsg Beacon.NoOp ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


letGo : Model -> Model
letGo model =
    { model | dragState = Beacon.NotDragging, dragCache = Nothing }


deleteBenchBlock : Model -> Int -> Model
deleteBenchBlock model benchIndex =
    { model
        | benchBlocks = Array.set benchIndex Nothing model.benchBlocks
        , dragCache = Nothing
    }


pickup : Model -> Beacon.DraggedItem DragBeaconId -> Model
pickup model draggedItem =
    case lookupDragged model draggedItem.beaconId of
        Ok lifeblock ->
            { model
                | dragState = Beacon.Dragging draggedItem
                , dragCache = Just lifeblock
            }

        Err _ ->
            Debug.todo "oops"


dropDraggedBlock :
    Model
    -> HoverState DragBeaconId DropBeaconId
    -> Result InvalidModel Model
dropDraggedBlock model { draggedItem, hoveredDropBeacon } =
    let
        benchAfterPickup : Result InvalidModel (Array (Maybe LifeBlock))
        benchAfterPickup =
            case BeaconId.dragLocation draggedItem.beaconId of
                BeaconId.Sidebar _ ->
                    Ok model.benchBlocks

                BeaconId.Bench { benchIndex, blockIndex } ->
                    case Array.get benchIndex model.benchBlocks of
                        Nothing ->
                            Err BoundsError

                        Just Nothing ->
                            Err InvalidDragState

                        Just (Just benchBlock) ->
                            case LifeBlock.splitAt benchBlock blockIndex of
                                LifeBlock.Whole _ ->
                                    Ok <| Array.set benchIndex Nothing model.benchBlocks

                                LifeBlock.Split ( left, _ ) ->
                                    Ok <| Array.set benchIndex (Just left) model.benchBlocks

                                LifeBlock.NotFound ->
                                    Err InvalidDragState

        draggedBlock : Result InvalidModel LifeBlock
        draggedBlock =
            lookupDragged model draggedItem.beaconId

        doDrop : Int -> Array (Maybe LifeBlock) -> LifeBlock -> Model
        doDrop benchIndex bench block =
            { model
                | benchBlocks = Array.set benchIndex (Just block) bench
                , dragState = Beacon.NotDragging
                , dragCache = Nothing
            }

        doFallibleDrop : Array (Maybe LifeBlock) -> Int -> (LifeBlock -> Result String LifeBlock) -> LifeBlock -> Model
        doFallibleDrop bench idx combine block =
            combine block
                |> Result.map (\combinedBlock -> doDrop idx bench combinedBlock)
                |> Result.withDefault (letGo model)

        combineAndDrop :
            Array (Maybe LifeBlock)
            -> Int
            -> (LifeBlock -> Result String LifeBlock)
            -> Result InvalidModel Model
        combineAndDrop bench benchIndex combine =
            Array.get benchIndex bench
                |> Result.fromMaybe BoundsError
                |> Result.map (Maybe.map <| doFallibleDrop bench benchIndex combine)
                |> Result.map (Maybe.withDefault <| letGo model)
    in
    Common.withBothOk benchAfterPickup draggedBlock <|
        \cleanBench lifeBlock ->
            case BeaconId.dropLocation hoveredDropBeacon of
                BeaconId.Open dropBenchIndex ->
                    Ok <| doDrop dropBenchIndex cleanBench lifeBlock

                BeaconId.Before dropBenchIndex ->
                    combineAndDrop cleanBench dropBenchIndex <|
                        \hoveredBlock -> LifeBlock.combine lifeBlock hoveredBlock

                BeaconId.After dropBenchIndex ->
                    combineAndDrop cleanBench dropBenchIndex <|
                        \hoveredBlock -> LifeBlock.combine hoveredBlock lifeBlock


{-| Look up a lifeblock in the model by its drag id (aka its original location).
-}
lookupDragged : Model -> DragBeaconId -> Result InvalidModel LifeBlock
lookupDragged ({ benchBlocks, sidebarLifepaths, dragCache } as model) dragId =
    case dragCache of
        Just cachedBlock ->
            Ok cachedBlock

        Nothing ->
            case BeaconId.dragLocation dragId of
                BeaconId.Bench { benchIndex, blockIndex } ->
                    case Array.get benchIndex benchBlocks of
                        Just (Just block) ->
                            case LifeBlock.splitAt block blockIndex of
                                LifeBlock.Whole resultBlock ->
                                    Ok resultBlock

                                LifeBlock.Split ( _, right ) ->
                                    Ok right

                                LifeBlock.NotFound ->
                                    Err InvalidDragState

                        Just Nothing ->
                            Err InvalidDragState

                        Nothing ->
                            Err BoundsError

                BeaconId.Sidebar sidebarIndex ->
                    case sidebarLifepaths of
                        Loaded paths ->
                            Array.get sidebarIndex paths
                                |> Maybe.map LifeBlock.singleton
                                |> Result.fromMaybe BoundsError

                        _ ->
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
    , benchBlocks : Array (Maybe LifeBlock)
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
            , searchFilter = model.searchFilter
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
        draggedLifeBlock : Beacon.DraggedItem DragBeaconId -> LifeBlock -> DraggedLifeBlock
        draggedLifeBlock draggedItem lifeBlock =
            { lifeBlock = lifeBlock
            , cursorOnScreen = draggedItem.cursorOnScreen
            , cursorOnDraggable = draggedItem.cursorOnDraggable
            }
    in
    case ( model.dragState, model.dragCache ) of
        ( Beacon.NotDragging, _ ) ->
            Ok Nothing

        ( Beacon.Dragging draggedItem, Just lifeBlock ) ->
            Ok <| Just <| draggedLifeBlock draggedItem lifeBlock

        ( Beacon.Hovering { draggedItem }, Just lifeBlock ) ->
            Ok <| Just <| draggedLifeBlock draggedItem lifeBlock

        _ ->
            Err InvalidDragState


type DragStateView
    = NotDraggingView
    | DraggingView LifeBlock
    | HoveringView HoverBeaconsView


type alias HoverBeaconsView =
    { dragBeacon : LifeBlock
    , dropBeacon : BeaconId.DropBeaconLocation
    }


lookupDragState : Model -> Result InvalidModel DragStateView
lookupDragState { dragState, dragCache } =
    case ( dragState, dragCache ) of
        ( Beacon.NotDragging, _ ) ->
            Ok NotDraggingView

        ( Beacon.Dragging _, Just cached ) ->
            Ok <| DraggingView cached

        ( Beacon.Hovering { hoveredDropBeacon }, Just cached ) ->
            Ok <|
                HoveringView
                    { dragBeacon = cached
                    , dropBeacon = BeaconId.dropLocation hoveredDropBeacon
                    }

        _ ->
            Err InvalidDragState


type InvalidModel
    = InvalidDragState
    | BoundsError


view : Model -> Element Msg
view model =
    case modelView model of
        Ok viewedModel ->
            row [ width fill, height fill, scrollbarY, spacing 40 ]
                [ viewSidebar viewedModel
                , viewWorkBench
                    viewedModel.benchBlocks
                    (getHoverState viewedModel.dragState)
                , viewDraggedBlock viewedModel.draggedLifeBlock
                ]

        Err _ ->
            Debug.todo "display an error message"


getHoverState : DragStateView -> Maybe HoverBeaconsView
getHoverState dragState =
    case dragState of
        HoveringView hover ->
            Just hover

        _ ->
            Nothing


viewWorkBench : Array (Maybe LifeBlock) -> Maybe HoverBeaconsView -> Element Msg
viewWorkBench slots hover =
    let
        viewSlot i block =
            case block of
                Just b ->
                    viewLifeBlock i Nothing b

                Nothing ->
                    openSlot i hover
    in
    row
        [ spacing 20
        , padding 40
        , centerX
        , centerY
        , height <| px 500
        , width fill
        ]
    <|
        Array.toList <|
            Array.indexedMap viewSlot slots


openSlot : Int -> Maybe HoverBeaconsView -> Element Msg
openSlot benchIndex hover =
    let
        beingHovered : Bool
        beingHovered =
            Maybe.map (\state -> state.dropBeacon == BeaconId.Open benchIndex) hover
                |> Maybe.withDefault False

        hoveringBlock : Maybe LifeBlock
        hoveringBlock =
            Maybe.map .dragBeacon hover
    in
    case ( beingHovered, hoveringBlock ) of
        ( True, Just block ) ->
            viewLifeBlock benchIndex (Just <| BeaconId.openSlotDropId benchIndex) block

        _ ->
            el
                (BeaconId.dropAttribute (BeaconId.openSlotDropId benchIndex)
                    :: Border.width 1
                    :: slotAttrs
                )
                (el [ centerX, centerY ] <| text "+")


viewLifeBlock : Int -> Maybe DropBeaconId -> LifeBlock -> Element Msg
viewLifeBlock benchIndex dropBeaconOverride block =
    LifeBlock.view
        { baseAttrs = slotAttrs
        , dropBeaconOverride = dropBeaconOverride
        , onDelete = Just <| DeleteBenchBlock benchIndex
        , benchIndex = benchIndex
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
        Beacon.subscriptions
            BeaconId.dragIdFromInt
            BeaconId.dropIdFromInt
            model.dragState
