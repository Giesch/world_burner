module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Colors
import Creation exposing (..)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Landing exposing (..)
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, s, string)


type alias Model =
    { page : Page }


type Page
    = LandingPage Landing.Model
    | CreationPage Creation.Model
    | NotFound


type Route
    = Landing
    | Creation


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotLandingMsg Landing.Msg
    | GotCreationMsg Creation.Msg
    | NoOp


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { page = LandingPage Landing.init }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    let
        content =
            case model.page of
                LandingPage landing ->
                    Landing.view landing |> Element.map GotLandingMsg

                CreationPage create ->
                    Creation.view create |> Element.map GotCreationMsg

                NotFound ->
                    el [ centerX, centerY ] <| text "Not Found"
    in
    { title = "World Burner"
    , body =
        [ Element.layout [] <|
            column [ width fill, height fill ]
                [ header
                , content
                ]
        ]
    }


header : Element Msg
header =
    row
        [ Region.navigation
        , width fill
        , height <| px 50
        , spacing 20
        , paddingXY 20 0
        , Background.color Colors.red
        ]
        [ accountButton "Log In" NoOp
        , accountButton "Create Account" NoOp
        ]


accountButton : String -> Msg -> Element Msg
accountButton label msg =
    Input.button
        [ alignRight
        , mouseOver <|
            [ Background.color Colors.white
            , Font.color Colors.black
            ]
        , height fill
        , Font.color Colors.white
        , Font.size 16
        , paddingXY 7 0
        ]
        { onPress = Just msg
        , label = text label
        }


logo : Element msg
logo =
    link
        [ height fill
        , paddingXY 10 0
        , mouseOver <|
            [ Background.color Colors.white
            , Font.color Colors.black
            ]
        , Font.color Colors.white
        ]
        { url = "/"
        , label = el [ alignLeft ] <| text "World Burner"
        }



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        }


updateUrl : Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    case Parser.parse parser url of
        Just Landing ->
            ( { model | page = LandingPage Landing.init }
            , Cmd.none
            )

        Just Creation ->
            ( { model | page = CreationPage Creation.init }
            , Cmd.none
            )

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Landing Parser.top
        , Parser.map Creation (s "create")
        ]
