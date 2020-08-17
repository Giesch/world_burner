module Creation.LifepathFilter exposing
    ( LifepathFilter
    , LifepathFilterOptions
    , apply
    , none
    , view
    , withFit
    , withSearchTerm
    )

import Array exposing (Array)
import Colors
import Common
import Element exposing (..)
import Element.Font as Font
import Element.Input as Input
import LifeBlock exposing (LifeBlock)
import Lifepath exposing (Lifepath)
import List.NonEmpty as NonEmpty


type alias LifepathFilter =
    { searchTerm : String
    , fit : Maybe LifeBlock.Fit
    }


none : LifepathFilter
none =
    { searchTerm = ""
    , fit = Nothing
    }


withSearchTerm : String -> LifepathFilter -> LifepathFilter
withSearchTerm searchTerm filter =
    { filter | searchTerm = searchTerm }


withFit : Maybe LifeBlock.Fit -> LifepathFilter -> LifepathFilter
withFit fit filter =
    { filter | fit = fit }


apply : LifepathFilter -> Array Lifepath -> Array Lifepath
apply filter lifepaths =
    Array.filter (include filter) lifepaths


include : LifepathFilter -> Lifepath -> Bool
include filter lifepath =
    includedByTerm filter lifepath && includedByFit filter lifepath


includedByTerm : LifepathFilter -> Lifepath -> Bool
includedByTerm filter lifepath =
    case String.toLower filter.searchTerm of
        "" ->
            True

        term ->
            List.any
                (\field -> String.contains term field)
                lifepath.searchContent


includedByFit : LifepathFilter -> Lifepath -> Bool
includedByFit filter lifepath =
    case filter.fit of
        Nothing ->
            True

        Just ( LifeBlock.Before, lifeBlock ) ->
            LifeBlock.combine (LifeBlock.singleton lifepath) lifeBlock
                |> Common.isOk

        Just ( LifeBlock.After, lifeBlock ) ->
            LifeBlock.combine lifeBlock (LifeBlock.singleton lifepath)
                |> Common.isOk


type alias LifepathFilterOptions msg =
    { enteredSearchText : String -> msg
    , clearFit : msg
    }


view : LifepathFilterOptions msg -> LifepathFilter -> Element msg
view { enteredSearchText, clearFit } { searchTerm, fit } =
    column [ alignRight, padding 40, width fill ]
        [ fitFilters { fit = fit, clearFit = clearFit }
        , searchInput enteredSearchText <| searchTerm
        ]


type alias FitOptions msg =
    { fit : Maybe LifeBlock.Fit
    , clearFit : msg
    }


fitFilters : FitOptions msg -> Element msg
fitFilters { fit, clearFit } =
    case fit of
        Nothing ->
            Element.none

        Just f ->
            viewFit clearFit f


viewFit : msg -> LifeBlock.Fit -> Element msg
viewFit clearFit ( position, block ) =
    let
        label =
            case position of
                LifeBlock.Before ->
                    "filter: fits before:"

                LifeBlock.After ->
                    "filter: fits after:"

        pathNames : List String
        pathNames =
            block
                |> LifeBlock.paths
                |> NonEmpty.toList
                |> List.map .name
    in
    row [ width fill ]
        [ Input.button [ width <| fillPortion 1 ]
            { onPress = Just clearFit
            , label = text "X"
            }
        , column [ width <| fillPortion 2 ]
            (text label :: List.map text pathNames)
        ]


searchInput : (String -> msg) -> String -> Element msg
searchInput enteredSearchText searchTerm =
    Input.search [ Font.color Colors.black ]
        { onChange = enteredSearchText
        , text = searchTerm
        , placeholder = Nothing
        , label = Input.labelAbove [] <| text "Search"
        }
