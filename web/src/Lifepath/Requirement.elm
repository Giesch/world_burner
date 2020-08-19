module Lifepath.Requirement exposing
    ( LifepathPredicate
    , Predicate(..)
    , PreviousLifepathsPredicate
    , Requirement
    , SettingPredicate
    , decoder
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import List.NonEmpty as NonEmpty exposing (NonEmpty)


type alias Requirement =
    { predicate : Predicate
    , description : String
    }


type Predicate
    = SpecificLifepath LifepathPredicate
    | PreviousLifepaths PreviousLifepathsPredicate
    | Setting SettingPredicate
    | Any (NonEmpty Predicate)
    | All (NonEmpty Predicate)


type alias LifepathPredicate =
    { lifepathId : Int
    , count : Int
    }


type alias PreviousLifepathsPredicate =
    { count : Int }


type alias SettingPredicate =
    { settingId : Int
    , count : Int
    }



-- DECODE


decoder : Decoder Requirement
decoder =
    Decode.succeed Requirement
        |> required "predicate" predicateDecoder
        |> required "description" Decode.string


predicateDecoder : Decoder Predicate
predicateDecoder =
    Decode.field "type" Decode.string
        |> Decode.andThen predicateDecoderFromType


predicateDecoderFromType : String -> Decoder Predicate
predicateDecoderFromType string =
    let
        value : Decoder a -> Decoder a
        value =
            Decode.field "value"
    in
    case string of
        "Lifepath" ->
            value lifepathPredicateDecoder

        "PreviousLifepaths" ->
            value previousDecoder

        "Setting" ->
            value settingPredicateDecoder

        "Any" ->
            value <| Decode.lazy (\_ -> anyDecoder)

        "All" ->
            value <| Decode.lazy (\_ -> allDecoder)

        _ ->
            Decode.fail ("Invalid predicate type: " ++ string)


lifepathPredicateDecoder : Decoder Predicate
lifepathPredicateDecoder =
    Decode.map SpecificLifepath <|
        (Decode.succeed LifepathPredicate
            |> required "lifepath_id" Decode.int
            |> required "count" Decode.int
        )


previousDecoder : Decoder Predicate
previousDecoder =
    Decode.map PreviousLifepaths <|
        (Decode.succeed PreviousLifepathsPredicate
            |> required "count" Decode.int
        )


settingPredicateDecoder : Decoder Predicate
settingPredicateDecoder =
    Decode.map Setting <|
        (Decode.succeed SettingPredicate
            |> required "setting_id" Decode.int
            |> required "count" Decode.int
        )


anyDecoder : Decoder Predicate
anyDecoder =
    Decode.map Any <| NonEmpty.decodeList predicateDecoder


allDecoder : Decoder Predicate
allDecoder =
    Decode.map All <| NonEmpty.decodeList predicateDecoder
