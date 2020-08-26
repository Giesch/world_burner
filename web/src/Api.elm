module Api exposing
    ( dwarves
    , lifepathsDecoder
    )

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (optional, required)
import Json.Encode as Encode
import Lifepath exposing (Lead, Lifepath, Skill, StatMod)
import Trait exposing (Trait)
import Url exposing (Url)


dwarves : (Result Http.Error (List Lifepath) -> msg) -> Cmd msg
dwarves toMsg =
    Http.get
        { url = "/api/lifepaths/dwarves"
        , expect = Http.expectJson toMsg lifepathsDecoder
        }


lifepathsDecoder : Decoder (List Lifepath)
lifepathsDecoder =
    Decode.succeed LifepathsResponse
        |> required "lifepaths" (Decode.list Lifepath.decoder)
        |> Decode.map .lifepaths


type alias LifepathsResponse =
    { lifepaths : List Lifepath }
