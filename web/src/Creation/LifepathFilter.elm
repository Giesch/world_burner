module Creation.LifepathFilter exposing
    ( LifepathFilter
    , LifepathFilterOptions
    , apply
    , none
    , view
    , withSearchTerm
    )

import Array exposing (Array)
import Colors
import Element exposing (..)
import Element.Font as Font
import Element.Input as Input
import LifeBlock exposing (LifeBlock)
import Lifepath exposing (Lifepath)
import List.NonEmpty as NonEmpty


type alias LifepathFilter =
    { searchTerm : String
    , fits : FitFilter
    }


type alias FitFilter =
    Maybe ( Position, LifeBlock )


type Position
    = Before
    | After


none : LifepathFilter
none =
    { searchTerm = ""
    , fits = Nothing
    }


withSearchTerm : String -> LifepathFilter -> LifepathFilter
withSearchTerm searchTerm filter =
    { filter | searchTerm = searchTerm }


apply : LifepathFilter -> Array Lifepath -> Array Lifepath
apply filter lifepaths =
    Array.filter (include filter) lifepaths


include : LifepathFilter -> Lifepath -> Bool
include filter lifepath =
    case String.toLower filter.searchTerm of
        "" ->
            True

        term ->
            List.any
                (\field -> String.contains term field)
                lifepath.searchContent


type alias LifepathFilterOptions msg =
    { enteredSearchText : String -> msg
    }


view : LifepathFilterOptions msg -> LifepathFilter -> Element msg
view opts { searchTerm, fits } =
    column [ alignRight, padding 40, width fill ]
        [ el [ alignRight ] <| fitFilters fits
        , searchInput opts.enteredSearchText <| searchTerm
        ]


fitFilters : FitFilter -> Element msg
fitFilters fits =
    let
        listPaths block =
            block
                |> LifeBlock.paths
                |> NonEmpty.toList
                |> List.map .name
                |> String.join " "
    in
    case fits of
        Nothing ->
            Element.none

        Just ( Before, block ) ->
            text <| "filter: fits before " ++ listPaths block

        Just ( After, block ) ->
            text <| "filter: fits after " ++ listPaths block


searchInput : (String -> msg) -> String -> Element msg
searchInput enteredSearchText searchTerm =
    Input.search [ Font.color Colors.black ]
        { onChange = enteredSearchText
        , text = searchTerm
        , placeholder = Nothing
        , label = Input.labelAbove [] <| text "Search"
        }
