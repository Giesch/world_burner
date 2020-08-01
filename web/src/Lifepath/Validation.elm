module Lifepath.Validation exposing
    ( Error(..)
    , Warning(..)
    , errors
    , warnings
    )

import Array exposing (Array)
import Lifepath exposing (Lifepath)
import Lifepath.Requirement as Requirement exposing (Requirement)
import List.NonEmpty as NonEmpty exposing (NonEmpty)
import String.Extra exposing (toTitleCase)


{-| A problem with a character that makes it immediately invalid.
ie a non-first born lifepath or a missing setting lead
-}
type Error
    = Error String


{-| A problem with a character that signifies it's incomplete.
ie a missing born lifepath or an unsatisfied requirement
-}
type Warning
    = Warning String


type alias Rule err =
    NonEmpty Lifepath -> Maybe err


{-| Takes a predicate and the PREVIOUS lifepaths of the character.
Returns if the previous lifepaths satisfy the predicate.
-}
pass : Requirement.Predicate -> Array Lifepath -> Bool
pass predicate previousPaths =
    case predicate of
        Requirement.SpecificLifepath { lifepathId, count } ->
            atLeast count (\lp -> lp.id == lifepathId) previousPaths

        Requirement.Setting { settingId, count } ->
            atLeast count (\lp -> lp.settingId == settingId) previousPaths

        Requirement.PreviousLifepaths { count } ->
            Array.length previousPaths >= count

        Requirement.Any predicates ->
            List.any (\pred -> pass pred previousPaths) predicates

        Requirement.All predicates ->
            List.all (\pred -> pass pred previousPaths) predicates


atLeast : Int -> (Lifepath -> Bool) -> Array Lifepath -> Bool
atLeast count pred lifepaths =
    lifepaths
        |> Array.filter pred
        |> Array.length
        |> (\length -> length >= count)


checkRequirements : NonEmpty Lifepath -> List Warning
checkRequirements lifepaths =
    let
        check : Lifepath -> Array Lifepath -> Requirement -> Maybe Warning
        check lifepath pastLifepaths requirement =
            if pass requirement.predicate pastLifepaths then
                Nothing

            else
                Just <| Warning <| toTitleCase lifepath.name ++ " requires " ++ requirement.description

        run : ( Array Lifepath, List Lifepath, List Warning ) -> List Warning
        run ( seen, unseen, warns ) =
            case unseen of
                [] ->
                    List.reverse warns

                lifepath :: rest ->
                    case Maybe.andThen (check lifepath seen) lifepath.requirement of
                        Nothing ->
                            run ( Array.push lifepath seen, rest, warns )

                        Just warn ->
                            run ( Array.push lifepath seen, rest, warn :: warns )
    in
    run ( Array.empty, NonEmpty.toList lifepaths, [] )


gottaBeBorn : Rule Warning
gottaBeBorn ( first, _ ) =
    if first.born then
        Nothing

    else
        Just <| Warning "A character's first lifepath must be a 'born' lifepath"


onlyBornFirst : Rule Error
onlyBornFirst ( _, rest ) =
    if List.all (\path -> not path.born) rest then
        Nothing

    else
        Just <| Error "Only a character's first lifepath may be a 'born' lifepath"


errors : NonEmpty Lifepath -> List Error
errors lifepaths =
    case onlyBornFirst lifepaths of
        Just error ->
            [ error ]

        Nothing ->
            []


warnings : NonEmpty Lifepath -> List Warning
warnings lifepaths =
    case gottaBeBorn lifepaths of
        Just bornWarning ->
            bornWarning :: checkRequirements lifepaths

        Nothing ->
            checkRequirements lifepaths
