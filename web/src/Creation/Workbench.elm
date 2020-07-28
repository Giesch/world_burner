module Creation.Workbench exposing
    ( BenchIndex
    , PickupLocation
    , Workbench
    , default
    , deleteBlock
    , drop
    , pickup
    )

import Array exposing (Array)
import LifeBlock exposing (LifeBlock, SplitResult(..))


type Workbench
    = Workbench (Array (Maybe LifeBlock))


type BenchIndex
    = BenchIndex Int


default : Workbench
default =
    Workbench <| Array.repeat 4 Nothing


deleteBlock : Workbench -> BenchIndex -> Workbench
deleteBlock (Workbench bench) (BenchIndex index) =
    Workbench <| Array.set index Nothing bench


type PickupLocation
    = PickupLocation
        { benchIndex : Int
        , blockIndex : Int
        }


type PickupError
    = PickupBoundsError
    | NoLifeBlock


pickup : Workbench -> PickupLocation -> Result PickupError ( Workbench, LifeBlock )
pickup (Workbench bench) (PickupLocation { benchIndex, blockIndex }) =
    case getBenchBlock benchIndex bench of
        OutOfBounds ->
            Err PickupBoundsError

        GotNothing ->
            Err NoLifeBlock

        GotBlock block ->
            case LifeBlock.splitAt block blockIndex of
                Whole pickedup ->
                    Ok ( Workbench <| Array.set benchIndex Nothing bench, pickedup )

                Split ( left, right ) ->
                    Ok ( Workbench <| Array.set benchIndex (Just left) bench, right )

                NotFound ->
                    Err PickupBoundsError


type DropLocation
    = Open BenchIndex
    | Before BenchIndex
    | After BenchIndex


type DropError
    = DropBoundsError
    | InvalidDropLocation
    | CombinationError String


drop : Workbench -> LifeBlock -> DropLocation -> Result DropError Workbench
drop (Workbench bench) droppedBlock location =
    let
        combineAndDrop : Int -> (LifeBlock -> Result String LifeBlock) -> Result DropError Workbench
        combineAndDrop benchIndex combine =
            case getBenchBlock benchIndex bench of
                OutOfBounds ->
                    Err DropBoundsError

                GotNothing ->
                    Err InvalidDropLocation

                GotBlock benchBlock ->
                    case combine benchBlock of
                        Ok combined ->
                            Ok <| Workbench <| Array.set benchIndex (Just combined) bench

                        Err err ->
                            Err <| CombinationError err
    in
    case location of
        Open (BenchIndex benchIndex) ->
            Ok <| Workbench <| Array.set benchIndex (Just droppedBlock) bench

        Before (BenchIndex benchIndex) ->
            combineAndDrop benchIndex <|
                \benchBlock -> LifeBlock.combine droppedBlock benchBlock

        After (BenchIndex benchIndex) ->
            combineAndDrop benchIndex <|
                \benchBlock -> LifeBlock.combine benchBlock droppedBlock


type GetResult
    = OutOfBounds
    | GotNothing
    | GotBlock LifeBlock


getBenchBlock : Int -> Array (Maybe LifeBlock) -> GetResult
getBenchBlock benchIndex bench =
    case Array.get benchIndex bench of
        Nothing ->
            OutOfBounds

        Just Nothing ->
            GotNothing

        Just (Just block) ->
            GotBlock block
