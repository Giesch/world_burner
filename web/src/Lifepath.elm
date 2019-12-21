module Lifepath exposing
    ( Lead
    , Lifepath
    , Skill
    , StatMod
    , StatModType(..)
    , decoder
    )

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (optional, required)
import Trait exposing (Trait)


type alias Lifepath =
    { id : Int
    , settingId : Int
    , name : String
    , page : Int
    , years : Int
    , statMod : Maybe StatMod
    , res : Int
    , leads : List Lead
    , genSkillPts : Int
    , skillPts : Int
    , traitPts : Int
    , skills : List Skill
    , traits : List Trait
    , born : Bool
    }


type alias StatMod =
    { taip : StatModType
    , value : Int
    }


type StatModType
    = Physical
    | Mental
    | Either
    | Both


type alias Skill =
    { displayName : String
    , page : Int
    , skillId : Int
    , magical : Bool
    , training : Bool
    , wise : Bool
    }


type alias Lead =
    { settingName : String
    , settingId : Int
    , settingPage : Int
    }



-- DECODE


decoder : Decoder Lifepath
decoder =
    Decode.succeed Lifepath
        |> required "id" Decode.int
        |> required "setting_id" Decode.int
        |> required "name" Decode.string
        |> required "page" Decode.int
        |> required "years" Decode.int
        |> optional "stat_mod" (Decode.map Just statModDecoder) Nothing
        |> required "res" Decode.int
        |> required "leads" (Decode.list leadDecoder)
        |> required "gen_skill_pts" Decode.int
        |> required "skill_pts" Decode.int
        |> required "trait_pts" Decode.int
        |> required "skills" (Decode.list skillDecoder)
        |> required "traits" (Decode.list Trait.decoder)
        |> required "born" Decode.bool


statModDecoder : Decoder StatMod
statModDecoder =
    Decode.succeed StatMod
        |> required "type" statModTypeDecoder
        |> required "value" Decode.int


statModTypeDecoder : Decoder StatModType
statModTypeDecoder =
    Decode.string |> Decode.andThen statModTypeFromString


statModTypeFromString : String -> Decoder StatModType
statModTypeFromString string =
    case String.toLower string of
        "physical" ->
            Decode.succeed Physical

        "mental" ->
            Decode.succeed Mental

        "either" ->
            Decode.succeed Either

        "both" ->
            Decode.succeed Both

        _ ->
            Decode.fail <| "Invalid stat mod type: " ++ string


leadDecoder : Decoder Lead
leadDecoder =
    Decode.succeed Lead
        |> required "setting_name" Decode.string
        |> required "setting_id" Decode.int
        |> required "setting_page" Decode.int


skillDecoder : Decoder Skill
skillDecoder =
    Decode.succeed Skill
        |> required "display_name" Decode.string
        |> required "page" Decode.int
        |> required "skill_id" Decode.int
        |> required "magical" Decode.bool
        |> required "training" Decode.bool
        |> required "wise" Decode.bool
