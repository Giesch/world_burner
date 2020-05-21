module Creation.BeaconId exposing
    ( DragBeaconId
    , DragBeaconLocation(..)
    , DropBeaconId
    , DropBeaconLocation(..)
    , dragAttribute
    , dragBeaconId
    , dragIdFromInt
    , dragLocation
    , dropAttribute
    , dropBeaconId
    , dropIdFromInt
    , isDropBeaconId
    , staticOpenSlot
    )

import Beacon
import Element


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
    | Bench
        { benchIndex : Int
        , blockIndex : Int
        }


{-| An opaque and deterministic location-based id for a drop area
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
    = Open Int
    | Before Int
    | After Int


{-| Creates a deterministic id for the given location on the Creation page
-}
dragBeaconId : DragBeaconLocation -> DragBeaconId
dragBeaconId location =
    case location of
        Bench { benchIndex, blockIndex } ->
            -- this uses the id range 0 through 99
            DragBeaconId (benchIndex * 10 + blockIndex)

        Sidebar sidebarIndex ->
            -- this uses the id range 100+
            DragBeaconId (100 + sidebarIndex)


dragLocation : DragBeaconId -> DragBeaconLocation
dragLocation (DragBeaconId id) =
    if id < 100 then
        Bench
            { benchIndex = tensPlace id
            , blockIndex = modBy 10 id
            }

    else
        Sidebar (id - 100)


tensPlace : Int -> Int
tensPlace n =
    if n >= 0 then
        (n - modBy 10 n) // 10

    else
        -1 * tensPlace -n


{-| Creates a deterministic id for the given location on the Creation page
-}
dropBeaconId : DropBeaconLocation -> DropBeaconId
dropBeaconId location =
    case location of
        Open index ->
            -- this uses the id range -1 through -10
            DropBeaconId ((index + 1) * -1)

        Before index ->
            -- this uses the id range -11 through -20
            DropBeaconId ((index + 11) * -1)

        After index ->
            -- this uses the id range -21 through -30
            DropBeaconId ((index + 21) * -1)


dragAttribute : DragBeaconId -> Element.Attribute msg
dragAttribute (DragBeaconId id) =
    Beacon.attribute id


dropAttribute : DropBeaconId -> Element.Attribute msg
dropAttribute (DropBeaconId id) =
    Beacon.attribute id


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
    if id < 0 then
        Just <| DropBeaconId id

    else
        Nothing


{-| TODO replace this
-}
staticOpenSlot : DropBeaconId
staticOpenSlot =
    DropBeaconId -1
