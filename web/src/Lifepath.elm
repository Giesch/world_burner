module Lifepath exposing
    ( Lead
    , Lifepath
    , Skill
    , StatMod
    , StatModType(..)
    , decoder
    , lifepathWidth
    , view
    )

import Colors exposing (..)
import Common
import Creation.BeaconId as BeaconId exposing (DragBeaconId)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (optional, required)
import Lifepath.Requirement as Requirement exposing (Requirement)
import String.Extra exposing (toTitleCase)
import Trait exposing (Trait)


type alias Lifepath =
    { id : Int
    , settingId : Int
    , settingName : String
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
    , requirement : Maybe Requirement
    , searchContent : List String
    }


type alias LifepathJson =
    { id : Int
    , settingId : Int
    , settingName : String
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
    , requirement : Maybe Requirement
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
    Decode.succeed LifepathJson
        |> required "id" Decode.int
        |> required "setting_id" Decode.int
        |> required "setting_name" Decode.string
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
        |> optional "requirement" (Decode.map Just Requirement.decoder) Nothing
        |> Decode.map addSearchContent


addSearchContent : LifepathJson -> Lifepath
addSearchContent json =
    { id = json.id
    , settingId = json.settingId
    , settingName = json.settingName
    , name = json.name
    , page = json.page
    , years = json.years
    , statMod = json.statMod
    , res = json.res
    , leads = json.leads
    , genSkillPts = json.genSkillPts
    , skillPts = json.skillPts
    , traitPts = json.traitPts
    , skills = json.skills
    , traits = json.traits
    , born = json.born
    , requirement = json.requirement
    , searchContent = searchContent json
    }


searchContent : LifepathJson -> List String
searchContent json =
    let
        skills : List String
        skills =
            List.map .displayName json.skills

        traits : List String
        traits =
            List.map Trait.name json.traits
    in
    json.name :: json.settingName :: skills ++ traits


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



-- VIEW


lifepathWidth : Element.Length
lifepathWidth =
    Element.px 300


view : { withBeacon : Maybe DragBeaconId } -> Lifepath -> Element msg
view { withBeacon } lifepath =
    let
        defaultAttrs : List (Attribute msg)
        defaultAttrs =
            [ Background.color Colors.white
            , Font.color Colors.black
            , Border.rounded 8
            , Border.color Colors.darkened
            , Border.width 1
            , padding 12
            , width lifepathWidth
            , spacing 10
            ]
                ++ Common.userSelectNone

        attrs =
            case withBeacon of
                Just beaconId ->
                    BeaconId.dragAttribute beaconId :: defaultAttrs

                Nothing ->
                    defaultAttrs
    in
    column attrs
        [ text <| toTitleCase lifepath.name ++ " (" ++ toTitleCase lifepath.settingName ++ ")"
        , row [ width fill, spaceEvenly ]
            [ text (String.fromInt lifepath.years ++ "yrs")
            , text (String.fromInt lifepath.res ++ "res")
            , viewLifepathStat lifepath.statMod
            ]
        , viewSkills lifepath.skillPts lifepath.skills
        , viewTraits lifepath.traitPts lifepath.traits
        , viewLeads lifepath.leads
        ]


viewSkills : Int -> List Skill -> Element msg
viewSkills pts skills =
    let
        skillNames =
            String.join ", " <| List.map (\sk -> toTitleCase <| .displayName sk) skills
    in
    case ( pts, List.length skills ) of
        ( 0, 0 ) ->
            none

        ( _, 0 ) ->
            paragraph []
                [ text ("Skills: " ++ String.fromInt pts) ]

        _ ->
            paragraph []
                [ text ("Skills: " ++ String.fromInt pts ++ ": " ++ skillNames) ]


viewLifepathStat : Maybe StatMod -> Element msg
viewLifepathStat statMod =
    case statMod of
        Nothing ->
            text <| "stat: --"

        Just mod ->
            text <| "stat: " ++ viewStatMod mod


viewLeads : List Lead -> Element msg
viewLeads leads =
    let
        leadNames =
            String.join ", " <|
                List.map (\lead -> toTitleCase <| .settingName lead) leads
    in
    if List.length leads == 0 then
        none

    else
        paragraph []
            [ text <| "Leads: " ++ leadNames ]


viewStatMod : StatMod -> String
viewStatMod statMod =
    let
        prefix =
            -- zero is not a permitted value in the db
            if statMod.value > 0 then
                "+"

            else
                "-"

        suffix =
            case statMod.taip of
                Physical ->
                    "P"

                Mental ->
                    "M"

                Either ->
                    "M/P"

                Both ->
                    "M,P"
    in
    prefix ++ String.fromInt statMod.value ++ suffix


viewTraits : Int -> List Trait -> Element msg
viewTraits pts traits =
    let
        traitNames =
            String.join ", " <| List.map (\tr -> toTitleCase <| Trait.name tr) traits
    in
    case ( pts, List.length traits ) of
        ( 0, 0 ) ->
            none

        ( _, 0 ) ->
            paragraph []
                [ text ("Traits: " ++ String.fromInt pts) ]

        _ ->
            paragraph []
                [ text ("Traits: " ++ String.fromInt pts ++ ": " ++ traitNames) ]
