module LifepathTest exposing (..)

import Api
import ExampleLifepathJson exposing (dwarves)
import Expect
import Json.Decode as Decode
import Lifepath exposing (Lifepath)
import Test exposing (..)


lifepathsDecoder : Test
lifepathsDecoder =
    describe "Lifepaths decoder"
        [ test "can decode the dwarves" <|
            \_ ->
                dwarves
                    |> Decode.decodeString Api.lifepathsDecoder
                    |> Expect.ok
        ]
