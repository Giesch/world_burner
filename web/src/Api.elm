module Api exposing
    ( ApiError
    , ApiResult
    , ErrorResponse
    , ErrorSource
    , LifepathFilters
    , ServerError
    , listLifepaths
    , noFilters
    , withBorn
    )

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (optional, required)
import Json.Encode as Encode
import Lifepath exposing (Lead, Lifepath, Skill, StatMod)
import Trait exposing (Trait)
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
    , searchTerm : Maybe String
    }


noFilters : LifepathFilters
noFilters =
    { born = Nothing
    , settingIds = Nothing
    , searchTerm = Nothing
    }


withBorn : LifepathFilters -> Maybe Bool -> LifepathFilters
withBorn filters born =
    { filters | born = born }


encodeLifepathFilters : LifepathFilters -> Encode.Value
encodeLifepathFilters filters =
    Encode.object
        [ ( "born", maybeEncode Encode.bool filters.born )
        , ( "setting_ids", maybeEncode (Encode.list Encode.int) filters.settingIds )
        , ( "search_term", maybeEncode Encode.string filters.searchTerm )
        ]


maybeEncode : (a -> Encode.Value) -> Maybe a -> Encode.Value
maybeEncode encoder =
    Maybe.map encoder >> Maybe.withDefault Encode.null


type alias LifepathsResponse =
    { lifepaths : List Lifepath }


lifepathsDecoder : Decoder (List Lifepath)
lifepathsDecoder =
    Decode.succeed LifepathsResponse
        |> required "lifepaths" (Decode.list Lifepath.decoder)
        |> Decode.map .lifepaths



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
        badBody =
            HttpError << Http.BadBody << Decode.errorToString
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
                        |> Result.andThen (Err << AppError)

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
        |> required "errors" (Decode.list errorDecoder)


errorDecoder : Decoder ServerError
errorDecoder =
    Decode.succeed ServerError
        |> required "title" Decode.string
        |> required "detail" Decode.string
        |> optional "source" (Decode.map Just sourceDecoder) Nothing


sourceDecoder : Decoder ErrorSource
sourceDecoder =
    Decode.succeed ErrorSource
        |> required "pointer" Decode.string
