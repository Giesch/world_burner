module Creation.BeaconId exposing
    ( DragBeaconId
    , DropBeaconId
    , isDropBeaconId
    )

import Beacon
import Element


type DragBeaconId
    = DragBeaconId Int


type DropBeaconId
    = DropBeaconId Int


dragAttribute : DragBeaconId -> Element.Attribute msg
dragAttribute (DragBeaconId i) =
    Beacon.attribute i


isDropBeaconId : Int -> Bool
isDropBeaconId n =
    n < 0
