module Creation exposing (..)

import Element exposing (..)


type alias Model =
    {}


init : Model
init =
    {}


view : Model -> Element a
view model =
    el [] <| text "what is going on"


type Msg
    = Msg
