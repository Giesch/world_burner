module Api.LifepathFilter exposing
    ( LifepathFilter
    , LifepathFilterOptions
    , default
    , view
    , withBorn
    , withSearchTerm
    , withSettingIds
    )

import Colors
import Element exposing (..)
import Element.Font as Font
import Element.Input as Input


type alias LifepathFilter =
    { born : Maybe Bool
    , settingIds : Maybe (List Int)
    , searchTerm : Maybe String
    }


default : LifepathFilter
default =
    { born = Just True
    , settingIds = Nothing
    , searchTerm = Nothing
    }


withBorn : Maybe Bool -> LifepathFilter -> LifepathFilter
withBorn born filter =
    { filter | born = born }


withSearchTerm : Maybe String -> LifepathFilter -> LifepathFilter
withSearchTerm searchTerm filter =
    { filter | searchTerm = searchTerm }


withSettingIds : Maybe (List Int) -> LifepathFilter -> LifepathFilter
withSettingIds settingIds filter =
    { filter | settingIds = settingIds }


type alias LifepathFilterOptions msg =
    { clickedBornCheckbox : Bool -> msg
    , enteredSearchText : String -> msg
    }


view : LifepathFilterOptions msg -> LifepathFilter -> Element msg
view opts { searchTerm, born } =
    column [ alignRight, padding 40, width fill ]
        [ bornCheckbox opts.clickedBornCheckbox <| Maybe.withDefault False born
        , searchInput opts.enteredSearchText <| Maybe.withDefault "" searchTerm
        ]


bornCheckbox : (Bool -> msg) -> Bool -> Element msg
bornCheckbox clickedBornCheckbox checked =
    Input.checkbox [ alignRight ]
        { onChange = clickedBornCheckbox
        , icon = Input.defaultCheckbox
        , checked = checked
        , label = Input.labelLeft [ alignRight ] <| text "Born"
        }


searchInput : (String -> msg) -> String -> Element msg
searchInput enteredSearchText searchTerm =
    Input.search [ Font.color Colors.black ]
        { onChange = enteredSearchText
        , text = searchTerm
        , placeholder = Nothing
        , label = Input.labelAbove [] <| text "Search"
        }
