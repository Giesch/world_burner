module Lifepath.Requirement exposing
    ( ReqPredicate(..)
    , Requirement
    , decoder
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)


type alias Requirement =
    { predicate : ReqPredicate
    , description : String
    }


type ReqPredicate
    = SpecificLifepath LifepathPredicate
    | PreviousLifepaths PreviousLifepathsPredicate
    | Setting SettingPredicate
    | Any (List ReqPredicate)
    | All (List ReqPredicate)


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


predicateDecoder : Decoder ReqPredicate
predicateDecoder =
    Decode.field "type" Decode.string
        |> Decode.andThen predicateDecoderFromType


predicateDecoderFromType : String -> Decoder ReqPredicate
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


lifepathPredicateDecoder : Decoder ReqPredicate
lifepathPredicateDecoder =
    Decode.map SpecificLifepath <|
        (Decode.succeed LifepathPredicate
            |> required "lifepath_id" Decode.int
            |> required "count" Decode.int
        )


previousDecoder : Decoder ReqPredicate
previousDecoder =
    Decode.map PreviousLifepaths <|
        (Decode.succeed PreviousLifepathsPredicate
            |> required "count" Decode.int
        )


settingPredicateDecoder : Decoder ReqPredicate
settingPredicateDecoder =
    Decode.map Setting <|
        (Decode.succeed SettingPredicate
            |> required "setting_id" Decode.int
            |> required "count" Decode.int
        )


anyDecoder : Decoder ReqPredicate
anyDecoder =
    Decode.map Any <| Decode.list predicateDecoder


allDecoder : Decoder ReqPredicate
allDecoder =
    Decode.map All <| Decode.list predicateDecoder
