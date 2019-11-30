module Session exposing (..)

import Browser.Navigation as Nav


type alias Session =
    { key : Nav.Key }
