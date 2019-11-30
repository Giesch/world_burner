module Creation exposing (..)

import Element exposing (..)
import Session exposing (..)


type alias Model =
    { session : Session }


init : Session -> Model
init session =
    { session = session }


type Msg
    = Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Element a
view model =
    el [] <| text "what is going on"
