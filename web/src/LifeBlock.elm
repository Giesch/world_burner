module LifeBlock exposing
    ( LifeBlock
    , SplitResult(..)
    , combine
    , errors
    , paths
    , singleton
    , splitAt
    , view
    , warnings
    )

import Array exposing (Array)
import Creation.BeaconId as BeaconId exposing (DragBeaconId, DropBeaconId)
import Element exposing (..)
import Element.Border as Border
import Element.Input as Input
import Lifepath exposing (Lifepath)
import Lifepath.Requirement as Requirement exposing (Requirement)
import List.NonEmpty as NonEmpty exposing (NonEmpty)
import String.Extra exposing (toTitleCase)


{-| A non-empty linked list of lifepaths with beacon ids.
-}
type LifeBlock
    = LifeBlock (NonEmpty Lifepath)


paths : LifeBlock -> NonEmpty Lifepath
paths (LifeBlock list) =
    list


singleton : Lifepath -> LifeBlock
singleton path =
    LifeBlock <| NonEmpty.singleton path


{-| Validates whether the blocks can be combined in order.
-}
combine : LifeBlock -> LifeBlock -> Result String LifeBlock
combine left ((LifeBlock rightData) as right) =
    let
        append : LifeBlock -> LifeBlock -> LifeBlock
        append (LifeBlock l) (LifeBlock r) =
            LifeBlock <| NonEmpty.append l r

        rightFirst : Lifepath
        rightFirst =
            NonEmpty.head rightData
    in
    if rightFirst.born then
        Err "A 'born' lifepath must be a character's first lifepath"

    else
        Ok <| append left right


type SplitResult a
    = Whole a
    | Split ( a, a )
    | NotFound


{-| Splits a LifeBlock at the given index.
ie 0 would be taking the whole thing, while 'length' would be out of bounds.
-}
splitAt : LifeBlock -> Int -> SplitResult LifeBlock
splitAt (LifeBlock ( first, rest )) index =
    let
        list : List Lifepath
        list =
            first :: rest
    in
    case ( List.take index list, List.drop index list ) of
        ( leftFirst :: leftRest, rightFirst :: rightRest ) ->
            Split <|
                ( LifeBlock ( leftFirst, leftRest )
                , LifeBlock ( rightFirst, rightRest )
                )

        ( [], rightFirst :: rightRest ) ->
            Whole <| LifeBlock ( rightFirst, rightRest )

        ( _ :: _, [] ) ->
            NotFound

        ( [], [] ) ->
            -- this is impossible
            NotFound


type alias ViewOptions msg =
    { baseAttrs : List (Attribute msg)
    , dropBeaconOverride : Maybe DropBeaconId -- used during hover
    , onDelete : Maybe msg
    , benchIndex : Int
    }


view : ViewOptions msg -> LifeBlock -> Element msg
view { baseAttrs, dropBeaconOverride, onDelete, benchIndex } (LifeBlock lifepaths) =
    let
        dropZone : DropBeaconId -> Element msg
        dropZone id =
            case dropBeaconOverride of
                Just _ ->
                    el (Border.width 1 :: baseAttrs)
                        (el [ centerX, centerY ] <| text "+")

                Nothing ->
                    el (BeaconId.dropAttribute id :: Border.width 1 :: baseAttrs)
                        (el [ centerX, centerY ] <| text "+")

        attrs : List (Attribute msg)
        attrs =
            List.filterMap identity [ warnAttr, dropAttr ] ++ baseAttrs

        dropAttr : Maybe (Attribute msg)
        dropAttr =
            dropBeaconOverride
                |> Maybe.map BeaconId.dropAttribute

        warnAttr : Maybe (Attribute msg)
        warnAttr =
            case dropBeaconOverride of
                Just _ ->
                    Nothing

                Nothing ->
                    warnings lifepaths
                        |> viewWarnings
                        |> Maybe.map Element.onRight

        withBeacon : Int -> Maybe DragBeaconId
        withBeacon blockIndex =
            case dropBeaconOverride of
                Just _ ->
                    Nothing

                Nothing ->
                    Just <| BeaconId.benchDragId { benchIndex = benchIndex, blockIndex = blockIndex }

        middle : List (Element msg)
        middle =
            Input.button [ alignRight ]
                { onPress = onDelete
                , label = text "X"
                }
                :: List.indexedMap
                    (\blockIndex path -> Lifepath.view path { withBeacon = withBeacon blockIndex })
                    (NonEmpty.toList lifepaths)
    in
    column attrs <|
        dropZone (BeaconId.beforeSlotDropId benchIndex)
            :: middle
            ++ [ dropZone <| BeaconId.afterSlotDropId benchIndex ]



-- VALIDATION


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


viewWarnings : List Warning -> Maybe (Element msg)
viewWarnings warns =
    let
        viewWarn (Warning msg) =
            text msg
    in
    case warns of
        [] ->
            Nothing

        nonEmpty ->
            Just <| column [] <| List.map viewWarn nonEmpty
