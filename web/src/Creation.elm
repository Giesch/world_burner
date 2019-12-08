module Creation exposing (..)

import Colors exposing (..)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Session exposing (..)


type alias Model =
    { session : Session }


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session }
    , Cmd.none
    )


type Msg
    = Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Element msg
view model =
    row [ width fill, height fill ] <|
        [ column
            [ width (fillPortion 1)
            , height fill
            , Background.color Colors.darkened
            , Font.color Colors.white
            ]
            [ el [ centerX, centerY ] <| text "sidebar"
            ]
        , column [ width (fillPortion 5), height fill ]
            [ el [ centerX, centerY ] <| text "main area"
            ]
        ]
