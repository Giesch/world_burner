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
view opts { searchTerm, fit } =
    column [ alignRight, padding 40, width fill ]
        [ el [ alignRight ] <| fitFilters fit
        , searchInput opts.enteredSearchText <| searchTerm
        ]


fitFilters : Maybe LifeBlock.Fit -> Element msg
fitFilters fits =
    let
        pathNames : LifeBlock -> String
        pathNames block =
            block
                |> LifeBlock.paths
                |> NonEmpty.toList
                |> List.map .name
                |> String.join " "
    in
    case fits of
        Nothing ->
            Element.none

        -- TODO buttons for clearing the fit
        Just ( LifeBlock.Before, block ) ->
            text <| "filter: fits before " ++ pathNames block

        Just ( LifeBlock.After, block ) ->
            text <| "filter: fits after " ++ pathNames block


searchInput : (String -> msg) -> String -> Element msg
searchInput enteredSearchText searchTerm =
    Input.search [ Font.color Colors.black ]
        { onChange = enteredSearchText
        , text = searchTerm
        , placeholder = Nothing
        , label = Input.labelAbove [] <| text "Search"
        }
