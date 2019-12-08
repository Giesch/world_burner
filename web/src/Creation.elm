module Creation exposing (..)

import Api exposing (ApiResult)
import Colors exposing (..)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Lifepath exposing (Lead, Lifepath, Skill, StatMod, StatModType(..))
import Session exposing (..)
import String.Extra exposing (toTitleCase)
import Trait exposing (Trait)


type alias Model =
    { session : Session
    , sidebarLifepaths : Status (List Lifepath)
    }


type Status a
    = Loading
    | Loaded a
    | Failed


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , sidebarLifepaths = Loading
      }
    , getBornLifepaths
    )


type Msg
    = GotBornLifepaths (ApiResult (List Lifepath))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotBornLifepaths (Ok bornLifepaths) ->
            ( { model | sidebarLifepaths = Loaded bornLifepaths }, Cmd.none )

        GotBornLifepaths (Err error) ->
            ( { model | sidebarLifepaths = Failed }, Cmd.none )


view : Model -> Element Msg
view model =
    row [ width fill, height fill ] <|
        [ column
            [ width (fillPortion 1)
            , height fill
            , Background.color Colors.darkened
            , Font.color Colors.white
            , spacing 20
            , padding 40
            ]
            (viewSidebar model.sidebarLifepaths)
        , column [ width (fillPortion 5), height fill ]
            [ el [ centerX, centerY ] <| none ]
        ]


viewSidebar : Status (List Lifepath) -> List (Element Msg)
viewSidebar status =
    case status of
        Loading ->
            [ text "loading..." ]

        Failed ->
            [ text "couldn't load born lifepaths" ]

        Loaded lifepaths ->
            List.map viewLifepath lifepaths


viewLifepath : Lifepath -> Element Msg
viewLifepath lifepath =
    column
        [ Background.color Colors.white
        , Font.color Colors.black
        , Border.rounded 8
        , padding 12
        , width fill
        , spacing 10
        ]
        [ text <| toTitleCase lifepath.name
        , row [ width fill, spaceEvenly ]
            [ text (String.fromInt lifepath.years ++ " years")
            , text (String.fromInt lifepath.res ++ " res")
            , viewLifepathStat lifepath.statMod
            ]
        , viewSkills lifepath.skillPts lifepath.skills
        , viewTraits lifepath.traitPts lifepath.traits
        , viewLeads lifepath.leads
        ]


viewLeads : List Lead -> Element Msg
viewLeads leads =
    let
        leadNames =
            String.join ", " <|
                List.map (\l -> toTitleCase <| .settingName l) leads
    in
    if List.length leads == 0 then
        none

    else
        text <| "Leads: " ++ leadNames


viewTraits : Int -> List Trait -> Element Msg
viewTraits pts traits =
    let
        traitNames =
            String.join ", " <| List.map (\tr -> toTitleCase <| Trait.name tr) traits
    in
    case ( pts, List.length traits ) of
        ( 0, 0 ) ->
            none

        ( _, 0 ) ->
            text ("Traits: " ++ String.fromInt pts)

        _ ->
            text ("Traits: " ++ String.fromInt pts ++ ": " ++ traitNames)


viewSkills : Int -> List Skill -> Element Msg
viewSkills pts skills =
    let
        skillNames =
            String.join ", " <| List.map (\sk -> toTitleCase <| .displayName sk) skills
    in
    case ( pts, List.length skills ) of
        ( 0, 0 ) ->
            none

        ( _, 0 ) ->
            text ("Skills: " ++ String.fromInt pts)

        _ ->
            text ("Skills: " ++ String.fromInt pts ++ ": " ++ skillNames)


viewLifepathStat : Maybe StatMod -> Element Msg
viewLifepathStat statMod =
    case statMod of
        Nothing ->
            text <| "stat: --"

        Just mod ->
            text <| "stat: " ++ viewStatMod mod


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
                    " P"

                Mental ->
                    " M"

                Either ->
                    " M/P"

                Both ->
                    " M,P"
    in
    prefix ++ String.fromInt statMod.value ++ suffix


getBornLifepaths : Cmd Msg
getBornLifepaths =
    Api.listLifepaths GotBornLifepaths bornFilter


bornFilter : Api.LifepathFilters
bornFilter =
    { born = Just True
    , settingIds = Nothing
    }
