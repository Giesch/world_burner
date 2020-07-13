module Api.LifepathFilter exposing (..)


type alias LifepathFilter =
    { born : Maybe Bool
    , settingIds : Maybe (List Int)
    , searchTerm : Maybe String
    }


none : LifepathFilter
none =
    { born = Nothing
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
