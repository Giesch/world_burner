module Creation.BeaconId exposing
    ( Beacon(..)
    , BenchIndex
    , BenchLocation
    , DragBeaconId
    , DragBeaconLocation(..)
    , DropBeaconId
    , DropBeaconLocation(..)
    , HoverBeaconId
    , HoverBeaconLocation(..)
    , attribute
    , decoders
    , drag
    , dragLocation
    , drop
    , dropLocation
    , encode
    , hover
    , hoverLocation
    )

import DragState
import Element
import Html.Attributes
import Json.Encode as Encode


type HoverBeaconId
    = HoverBeaconId Int


type HoverBeaconLocation
    = LifeBlockWarning WarningLocation
    | HoverBefore BenchIndex
    | HoverAfter BenchIndex


type alias WarningLocation =
    { benchIndex : BenchIndex
    , warningIndex : Int
    }


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
type
    DropBeaconLocation
    -- TODO rename these variants
    = Open BenchIndex
    | Before BenchIndex
    | After BenchIndex


type alias BenchIndex =
    Int


drag : DragBeaconLocation -> Beacon
drag location =
    case location of
        Bench loc ->
            Drag <| benchDragId loc

        Sidebar i ->
            Drag <| sidebarDragId i


drop : DropBeaconLocation -> Beacon
drop location =
    case location of
        Open benchIndex ->
            Drop <| openSlotDropId benchIndex

        Before benchIndex ->
            Drop <| beforeSlotDropId benchIndex

        After benchIndex ->
            Drop <| afterSlotDropId benchIndex


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


hover : HoverBeaconLocation -> Beacon
hover location =
    Hover <|
        case location of
            LifeBlockWarning warningLocation ->
                warningHoverId warningLocation

            HoverBefore benchIndex ->
                beforeSlotHoverId benchIndex

            HoverAfter benchIndex ->
                afterSlotHoverId benchIndex


warningHoverId : WarningLocation -> HoverBeaconId
warningHoverId { benchIndex, warningIndex } =
    -- this uses the id range -61 through -100
    HoverBeaconId (((benchIndex * 10 + warningIndex) + 61) * -1)


beforeSlotHoverId : Int -> HoverBeaconId
beforeSlotHoverId benchIndex =
    -- this uses the id range -41 through -50
    HoverBeaconId ((benchIndex + 41) * -1)


afterSlotHoverId : Int -> HoverBeaconId
afterSlotHoverId benchIndex =
    -- this uses the id range -51 through -60
    HoverBeaconId ((benchIndex + 51) * -1)


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
    if id < -60 && id >= -100 then
        LifeBlockWarning
            { benchIndex = tensPlace (id * -1 - 61)
            , warningIndex = modBy 10 (id * -1 - 61)
            }

    else if id < -40 && id >= -50 then
        HoverBefore ((id * -1) - 41)

    else if id < -50 && id >= -60 then
        HoverAfter ((id * -1) - 51)

    else
        -- TODO it is time to fix this mess
        -- reread what this is currently doing in a full serialization loop
        -- move the id decoders/encoders to this module
        -- come up with a nice structured way to handle encoding/decoding the ids
        Debug.todo "fix this module, this is a bad way to do things"


tensPlace : Int -> Int
tensPlace n =
    if n >= 0 then
        (n - modBy 10 n) // 10

    else
        -1 * tensPlace -n



-- DECODE


decoders : DragState.IdDecoders DragBeaconId DropBeaconId HoverBeaconId
decoders =
    { toDragId = dragIdFromInt
    , toDropId = dropIdFromInt
    , toHoverId = hoverIdFromInt
    }


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
    if id < -30 && id > -100 then
        Just <| HoverBeaconId id

    else
        Nothing



-- ENCODE


type Beacon
    = Drag DragBeaconId
    | Drop DropBeaconId
    | Hover HoverBeaconId


encode : Beacon -> Encode.Value
encode beacon =
    case beacon of
        Drag (DragBeaconId id) ->
            Encode.int id

        Drop (DropBeaconId id) ->
            Encode.int id

        Hover (HoverBeaconId id) ->
            Encode.int id


attribute : Beacon -> Element.Attribute msg
attribute beacon =
    Element.htmlAttribute <|
        -- NOTE this must match the attribute in draggable.js
        Html.Attributes.attribute "data-beacon"
            (Encode.encode 0 <| encode beacon)
