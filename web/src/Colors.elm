module Colors exposing (black, darkened, disabledRed, faint, red, white)

import Element exposing (Color, fromRgb255, rgb255, rgba255)


type alias Rgb255Record =
    { red : Int
    , green : Int
    , blue : Int
    , alpha : Float
    }


white : Color
white =
    rgb255 255 255 255


black : Color
black =
    rgb255 0 0 0


red : Color
red =
    fromRgb255 redVals


disabledRed : Color
disabledRed =
    fromRgb255 { redVals | alpha = 0.5 }


redVals : Rgb255Record
redVals =
    { red = 196
    , green = 32
    , blue = 14
    , alpha = 1.0
    }


darkened : Color
darkened =
    rgba255 0 0 0 0.8


faint : Color
faint =
    rgba255 0 0 0 0.1
