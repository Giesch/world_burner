module Api exposing
    ( ApiError
    , ApiResult
    , ErrorResponse
    , ErrorSource
    , Lead
    , Lifepath
    , LifepathFilters
    , ServerError
    , Skill
    , StatMod
    , listLifepaths
    )

import Dict exposing (Dict)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Url exposing (Url)


listLifepaths : (ApiResult (List Lifepath) -> msg) -> LifepathFilters -> Cmd msg
listLifepaths toMsg filters =
    Http.post
        { url = "/api/lifepaths/search"
        , body = Http.jsonBody <| encodeLifepathFilters filters
        , expect = expect lifepathsDecoder toMsg
        }


type alias LifepathFilters =
    { born : Maybe Bool
    , settingIds : Maybe (List Int)
    }


type alias Lifepath =
    { id : Int
    , settingId : Int
    , name : String
    , page : Int
    , years : Int
    , statMod : StatMod
    , res : Int
    , leads : List Lead
    , genSkillPts : Int
    , skillPts : Int
    , traitPts : Int
    , skills : List Skill
    }


type StatMod
    = Physical Int
    | Mental Int
    | Either Int
    | Both Int


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


encodeLifepathFilters : LifepathFilters -> Encode.Value
encodeLifepathFilters filters =
    Encode.object
        [ ( "born", maybeEncode Encode.bool filters.born )
        , ( "setting_ids", maybeEncode (Encode.list Encode.int) filters.settingIds )
        ]


maybeEncode : (a -> Encode.Value) -> Maybe a -> Encode.Value
maybeEncode encoder maybe =
    Maybe.map encoder maybe
        |> Maybe.withDefault Encode.null


type alias LifepathsResponse =
    { lifepaths : List Lifepath }


lifepathsDecoder : Decoder (List Lifepath)
lifepathsDecoder =
    Decode.succeed LifepathsResponse
        |> Pipeline.required "lifepaths" (Decode.list lifepathDecoder)
        |> Decode.map .lifepaths


lifepathDecoder : Decoder Lifepath
lifepathDecoder =
    Decode.succeed Lifepath
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "setting_id" Decode.int
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "page" Decode.int
        |> Pipeline.required "years" Decode.int
        |> Pipeline.required "stat_mod" statModDecoder
        |> Pipeline.required "res" Decode.int
        |> Pipeline.required "leads" (Decode.list leadDecoder)
        |> Pipeline.required "gen_skill_pts" Decode.int
        |> Pipeline.required "skill_pts" Decode.int
        |> Pipeline.required "trait_pts" Decode.int
        |> Pipeline.required "skills" (Decode.list skillDecoder)


statModDecoder : Decoder StatMod
statModDecoder =
    Decode.field "type" Decode.string
        |> Decode.andThen whichStatMod


statModTypes : Dict String (Int -> StatMod)
statModTypes =
    Dict.fromList
        [ ( "physical", Physical )
        , ( "mental", Mental )
        , ( "either", Either )
        , ( "both", Both )
        ]


whichStatMod : String -> Decoder StatMod
whichStatMod taip =
    let
        decode =
            \const -> Decode.map const <| Decode.field "value" Decode.int

        fail =
            Decode.fail ("Invalid stat mod type: " ++ taip)
    in
    Dict.get (String.toLower taip) statModTypes
        |> Maybe.map decode
        |> Maybe.withDefault fail


leadDecoder : Decoder Lead
leadDecoder =
    Decode.succeed Lead
        |> Pipeline.required "setting_name" Decode.string
        |> Pipeline.required "setting_id" Decode.int
        |> Pipeline.required "setting_page" Decode.int


skillDecoder : Decoder Skill
skillDecoder =
    Decode.succeed Skill
        |> Pipeline.required "display_name" Decode.string
        |> Pipeline.required "page" Decode.int
        |> Pipeline.required "skill_id" Decode.int
        |> Pipeline.required "magical" Decode.bool
        |> Pipeline.required "training" Decode.bool
        |> Pipeline.required "wise" Decode.bool



-- Http expect


{-| Generic Http expect with custom error type
-}
expect : Decoder v -> (Result (ApiError ErrorResponse) v -> msg) -> Http.Expect msg
expect =
    genericExpect errorRespDecoder


{-| Generic Http expect
This allows representing meaningful json errors
-}
genericExpect :
    Decoder e
    -> Decoder v
    -> (Result (ApiError e) v -> msg)
    -> Http.Expect msg
genericExpect errDecoder valDecoder toMsg =
    let
        badBody : Decode.Error -> ApiError e
        badBody err =
            HttpError <| Http.BadBody <| Decode.errorToString err
    in
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err <| HttpError <| Http.BadUrl url

                Http.Timeout_ ->
                    Err <| HttpError Http.Timeout

                Http.NetworkError_ ->
                    Err <| HttpError Http.NetworkError

                Http.BadStatus_ _ body ->
                    Decode.decodeString errDecoder body
                        |> Result.mapError badBody
                        |> Result.andThen (\resp -> Err <| AppError resp)

                Http.GoodStatus_ _ body ->
                    Decode.decodeString valDecoder body
                        |> Result.mapError badBody



-- Errors


type alias ApiResult a =
    Result (ApiError ErrorResponse) a


type ApiError e
    = HttpError Http.Error
    | AppError e


type alias ErrorResponse =
    { errors : List ServerError }


type alias ServerError =
    { title : String
    , detail : String
    , source : Maybe ErrorSource
    }


type alias ErrorSource =
    { pointer : String }


errorRespDecoder : Decoder ErrorResponse
errorRespDecoder =
    Decode.succeed ErrorResponse
        |> Pipeline.required "errors" (Decode.list errorDecoder)


errorDecoder : Decoder ServerError
errorDecoder =
    Decode.succeed ServerError
        |> Pipeline.required "title" Decode.string
        |> Pipeline.required "detail" Decode.string
        |> Pipeline.optional "source" (Decode.map Just sourceDecoder) Nothing


sourceDecoder : Decoder ErrorSource
sourceDecoder =
    Decode.succeed ErrorSource
        |> Pipeline.required "pointer" Decode.string
