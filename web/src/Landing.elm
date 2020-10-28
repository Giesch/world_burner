module Landing exposing (..)

{-| The default landing page.
-}

import Colors exposing (..)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Session exposing (..)


type alias Model =
    { session : Session }


type Msg
    = Msg


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Element a
view model =
    textColumn [ centerX, centerY, spacing 18, padding 10 ]
        [ el [] <| text "This is the landing page."
        , el [] <| paragraph [] [ text lorem ]
        , linkButton "Create a Character" "/create"
        ]


linkButton : String -> String -> Element msg
linkButton txt url =
    let
        attrs =
            [ alignRight
            , padding 12
            , Background.color Colors.red
            , Font.color Colors.white
            , Border.rounded 8
            ]
    in
    link []
        { url = url
        , label = el attrs <| text txt
        }


lorem : String
lorem =
    "Augue eget arcu dictum varius duis at consectetur lorem donec massa sapien, faucibus et. Egestas diam in arcu cursus euismod quis viverra nibh cras pulvinar? Urna condimentum mattis pellentesque id nibh tortor, id aliquet lectus proin nibh nisl, condimentum id venenatis a, condimentum vitae sapien pellentesque habitant. Ullamcorper morbi tincidunt ornare massa, eget egestas purus viverra accumsan in nisl nisi, scelerisque eu ultrices vitae, auctor eu augue ut lectus arcu, bibendum at varius vel, pharetra vel turpis? Enim, sit amet venenatis urna. Aliquam vestibulum morbi blandit cursus risus, at ultrices mi tempus imperdiet. Neque convallis a cras semper auctor neque, vitae tempus quam. Ultricies integer quis auctor elit sed vulputate mi sit amet mauris commodo quis imperdiet massa tincidunt nunc pulvinar sapien et ligula ullamcorper malesuada proin libero! Nulla facilisi nullam vehicula ipsum a arcu cursus vitae congue mauris rhoncus aenean vel elit scelerisque mauris pellentesque pulvinar pellentesque habitant morbi."
