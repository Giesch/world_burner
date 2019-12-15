module Geom exposing (..)


type alias Point =
    { x : Float
    , y : Float
    }


type alias Box =
    { x : Float
    , y : Float
    , width : Float
    , height : Float
    }


bounds : Box -> Point -> Bool
bounds box cursor =
    (cursor.x > box.x)
        && (cursor.y > box.y)
        && (cursor.x < box.x + box.width)
        && (cursor.y < box.y + box.height)


center : Box -> Point
center { x, y, width, height } =
    { x = x + (width / 2)
    , y = y + (height / 2)
    }


distance : Point -> Point -> Float
distance a b =
    let
        dx =
            a.x - b.x

        dy =
            a.y - b.y
    in
    sqrt ((dx ^ 2) + (dy ^ 2))
