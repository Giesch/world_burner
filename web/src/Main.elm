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
import Session exposing (..)
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, s, string)


type Model
    = Landing Landing.Model
    | Creation Creation.Model
    | NotFound Session


type Route
    = LandingRoute
    | CreationRoute


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( Landing (Landing.init { key = key }), Cmd.none )



-- UPDATE


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotLandingMsg Landing.Msg
    | GotCreationMsg Creation.Msg
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( ChangedUrl url, _ ) ->
            updateUrl url model

        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.External href ->
                    ( model, Nav.load href )

                Browser.Internal url ->
                    ( model, Nav.pushUrl (.key (toSession model)) (Url.toString url) )

        ( GotLandingMsg subMsg, Landing landing ) ->
            Landing.update subMsg landing
                |> updateWith Landing GotLandingMsg

        ( GotCreationMsg subMsg, Creation creation ) ->
            Creation.update subMsg creation
                |> updateWith Creation GotCreationMsg

        ( NoOp, _ ) ->
            ( model, Cmd.none )

        ( _, _ ) ->
            -- recieved a msg for the wrong page
            ( model, Cmd.none )


updateWith :
    (subModel -> Model)
    -> (subMsg -> Msg)
    -> ( subModel, Cmd subMsg )
    -> ( Model, Cmd Msg )
updateWith toModel toMsg ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )


toSession : Model -> Session
toSession model =
    case model of
        Landing landing ->
            landing.session

        Creation creation ->
            creation.session

        NotFound session ->
            session


updateUrl : Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    let
        session =
            toSession model
    in
    case Parser.parse parser url of
        Just LandingRoute ->
            ( Landing (Landing.init session)
            , Cmd.none
            )

        Just CreationRoute ->
            ( Creation (Creation.init session)
            , Cmd.none
            )

        Nothing ->
            ( NotFound session, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    let
        content =
            case model of
                Landing landing ->
                    Landing.view landing |> Element.map GotLandingMsg

                Creation create ->
                    Creation.view create |> Element.map GotCreationMsg

                NotFound session ->
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
        [ logo
        , headerButton "Log In" NoOp
        , headerButton "Register" NoOp
        ]


headerButton : String -> Msg -> Element Msg
headerButton label msg =
    Input.button
        [ alignRight
        , height fill
        , Font.color Colors.white
        , Font.size 16
        , paddingXY 7 0
        , mouseOver <|
            [ Background.color Colors.white
            , Font.color Colors.black
            ]
        ]
        { onPress = Just msg
        , label = text label
        }


logo : Element msg
logo =
    link
        [ height fill
        , paddingXY 10 0
        , Font.color Colors.white
        , mouseOver <|
            [ Background.color Colors.white
            , Font.color Colors.black
            ]
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


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map LandingRoute Parser.top
        , Parser.map CreationRoute (s "create")
        ]
