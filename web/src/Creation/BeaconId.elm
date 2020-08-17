module Creation.BeaconId exposing
    ( BenchIndex
    , BenchLocation
    , DragBeaconId
    , DragBeaconLocation(..)
    , DropBeaconId
    , DropBeaconLocation(..)
    , HoverBeaconId
    , HoverBeaconLocation(..)
    , afterSlotDropId
    , afterSlotHoverId
    , beforeSlotDropId
    , beforeSlotHoverId
    , benchDragId
    , dragAttribute
    , dragIdFromInt
    , dragLocation
    , dropAttribute
    , dropIdFromInt
    , dropLocation
    , hoverAttribute
    , hoverIdFromInt
    , hoverLocation
    , isDropBeaconId
    , openSlotDropId
    , sidebarDragId
    , warningHoverId
    )

import DragState
import Element


type HoverBeaconId
    = HoverBeaconId Int


type HoverBeaconLocation
    = LifeBlockWarning BenchIndex
    | HoverBefore BenchIndex
    | HoverAfter BenchIndex


{-| An opaque and deterministic location-based id for a draggable item
-}
type DragBeaconId
    = DragBeaconId Int


{-| The location of a drag beacon in the Creation page model

  - benchIndex - 0 based index on the workbench (must be less than 10)
  - blockIndex - 0 based index within the lifeblock (must be less than 10)

-}
type DragBeaconLocation
    = Sidebar Int
    | Bench BenchLocation


type alias BenchLocation =
    { benchIndex : BenchIndex
    , blockIndex : Int
    }


{-| An opaque and deterministic location-based id for a drop location
-}
type DropBeaconId
    = DropBeaconId Int


{-| The location of a drop beacon in the Creation page model.
All indexes are 0 based and must be less than 10.

  - Open - an empty slot on the workbench at the given index
  - Before - the drop area before/above the lifeblock at a given index
  - After - the drop area after/below the lifeblock at a given index

-}
type DropBeaconLocation
    = Open BenchIndex
    | Before BenchIndex
    | After BenchIndex


type alias BenchIndex =
    Int


{-| Creates a deterministic id for the given bench location on the Creation page
-}
benchDragId : BenchLocation -> DragBeaconId
benchDragId { benchIndex, blockIndex } =
    -- this uses the id range 0 through 99
    DragBeaconId (benchIndex * 10 + blockIndex)


{-| Creates a deterministic id for the given sidebar index on the Creation page
-}
sidebarDragId : Int -> DragBeaconId
sidebarDragId sidebarIndex =
    -- this uses the id range 100+
    DragBeaconId (100 + sidebarIndex)


{-| Creates a deterministic id for an open slot on the Creation page
The bench index must be between 0 and 9 inclusive
-}
openSlotDropId : Int -> DropBeaconId
openSlotDropId benchIndex =
    -- this uses the id range -1 through -10
    DropBeaconId ((benchIndex + 1) * -1)


{-| Creates a deterministic id for the area before/above a slot on the Creation page
The bench index must be between 0 and 9 inclusive
-}
beforeSlotDropId : Int -> DropBeaconId
beforeSlotDropId benchIndex =
    -- this uses the id range -11 through -20
    DropBeaconId ((benchIndex + 11) * -1)


{-| Creates a deterministic id for the area below/after a slot on the Creation page
The bench index must be between 0 and 9 inclusive
-}
afterSlotDropId : Int -> DropBeaconId
afterSlotDropId benchIndex =
    -- this uses the id range -21 through -30
    DropBeaconId ((benchIndex + 21) * -1)


warningHoverId : Int -> HoverBeaconId
warningHoverId benchIndex =
    -- this uses the id range -31 through -40
    HoverBeaconId ((benchIndex + 31) * -1)


beforeSlotHoverId : Int -> HoverBeaconId
beforeSlotHoverId benchIndex =
    -- this uses the id range -41 through -50
    HoverBeaconId ((benchIndex + 41) * -1)


afterSlotHoverId : Int -> HoverBeaconId
afterSlotHoverId benchIndex =
    -- this uses the id range -51 through -60
    HoverBeaconId ((benchIndex + 51) * -1)


dragLocation : DragBeaconId -> DragBeaconLocation
dragLocation (DragBeaconId id) =
    if id < 100 then
        Bench
            { benchIndex = tensPlace id
            , blockIndex = modBy 10 id
            }

    else
        Sidebar (id - 100)


dropLocation : DropBeaconId -> DropBeaconLocation
dropLocation (DropBeaconId id) =
    if id < 0 && id >= -10 then
        Open ((id * -1) - 1)

    else if id < -10 && id >= -20 then
        Before ((id * -1) - 11)

    else
        -- This relies on the range check in dropIdFromInt
        After ((id * -1) - 21)


hoverLocation : HoverBeaconId -> HoverBeaconLocation
hoverLocation (HoverBeaconId id) =
    if id < -30 && id >= -40 then
        LifeBlockWarning ((id * -1) - 31)

    else if id < -40 && id >= -50 then
        HoverBefore ((id * -1) - 41)

    else if id < -50 && id >= -60 then
        HoverAfter ((id * -1) - 51)

    else
        Debug.todo "fix this module, this is a bad way to do things"


tensPlace : Int -> Int
tensPlace n =
    if n >= 0 then
        (n - modBy 10 n) // 10

    else
        -1 * tensPlace -n


dragAttribute : DragBeaconId -> Element.Attribute msg
dragAttribute (DragBeaconId id) =
    DragState.attribute id


dropAttribute : DropBeaconId -> Element.Attribute msg
dropAttribute (DropBeaconId id) =
    DragState.attribute id


hoverAttribute : HoverBeaconId -> Element.Attribute msg
hoverAttribute (HoverBeaconId id) =
    DragState.attribute id


isDropBeaconId : Int -> Bool
isDropBeaconId n =
    n < 0


dragIdFromInt : Int -> Maybe DragBeaconId
dragIdFromInt id =
    if id >= 0 then
        Just <| DragBeaconId id

    else
        Nothing


dropIdFromInt : Int -> Maybe DropBeaconId
dropIdFromInt id =
    if id < 0 && id >= -30 then
        Just <| DropBeaconId id

    else
        Nothing


hoverIdFromInt : Int -> Maybe HoverBeaconId
hoverIdFromInt id =
    if id < -30 && id > -60 then
        Just <| HoverBeaconId id

    else
        Nothing
