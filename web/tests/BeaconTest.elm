module BeaconTest exposing (..)

import Creation.Beacon as Beacon
import Expect
import Fuzz exposing (Fuzzer)
import Test exposing (..)


dragIds : Test
dragIds =
    describe "toDragId and fromDragId are inverses"
        [ fuzz Fuzz.int "beginning from id" <|
            \randomId ->
                randomId
                    |> Beacon.fromDragId
                    |> Beacon.toDragId
                    |> Expect.equal randomId
        , fuzz dragLocation "beginning from location" <|
            \randomLocation ->
                randomLocation
                    |> Beacon.toDragId
                    |> Beacon.fromDragId
                    |> Expect.equal randomLocation
        ]


dropIds : Test
dropIds =
    describe "toDropId and fromDropId are inverses"
        [ fuzz Fuzz.int "beginning from id" <|
            \randomId ->
                randomId
                    |> Beacon.fromDropId
                    |> Beacon.toDropId
                    |> Expect.equal randomId
        , fuzz dropLocation "beginning from location" <|
            \randomLocation ->
                randomLocation
                    |> Beacon.toDropId
                    |> Beacon.fromDropId
                    |> Expect.equal randomLocation
        ]


hoverIds : Test
hoverIds =
    describe "toHoverId and fromHoverId are inverses"
        [ fuzz Fuzz.int "beginning from id" <|
            \randomId ->
                randomId
                    |> Beacon.fromHoverId
                    |> Beacon.toHoverId
                    |> Expect.equal randomId
        , fuzz hoverLocation "beginning from location" <|
            \randomLocation ->
                randomLocation
                    |> Beacon.toHoverId
                    |> Beacon.fromHoverId
                    |> Expect.equal randomLocation
        ]


dragLocation : Fuzzer Beacon.DragBeaconLocation
dragLocation =
    Fuzz.oneOf
        [ Fuzz.map Beacon.Sidebar singleDigit
        , Fuzz.map Beacon.Bench benchLocation
        ]


benchLocation : Fuzzer Beacon.BenchLocation
benchLocation =
    Fuzz.map2 Beacon.BenchLocation
        singleDigit
        singleDigit


dropLocation : Fuzzer Beacon.DropBeaconLocation
dropLocation =
    Fuzz.oneOf
        [ Fuzz.map Beacon.OpenSlot singleDigit
        , Fuzz.map Beacon.BeforeSlot singleDigit
        , Fuzz.map Beacon.AfterSlot singleDigit
        ]


hoverLocation : Fuzzer Beacon.HoverBeaconLocation
hoverLocation =
    Fuzz.oneOf
        [ Fuzz.map Beacon.LifeBlockWarning warningLocation
        , Fuzz.map Beacon.HoverBefore singleDigit
        , Fuzz.map Beacon.HoverAfter singleDigit
        ]


warningLocation : Fuzzer Beacon.WarningLocation
warningLocation =
    Fuzz.map2 Beacon.WarningLocation
        singleDigit
        singleDigit


singleDigit : Fuzzer Beacon.BenchIndex
singleDigit =
    Fuzz.intRange 0 9
