module LifeBlock exposing
    ( LifeBlock
    , dragNewBlock
    , fromPath
    )

import Array exposing (Array)
import Dict exposing (Dict)
import Lifepath exposing (Lifepath)


type alias LifeBlock =
    { first : Lifepath
    , rest : Array Lifepath
    }


type alias Model a =
    -- TODO should this be an opaque submodel managed by this module?
    { a
        | nextBlockId : Int
        , blocks : Dict Int LifeBlock
    }


fromPath : Lifepath -> LifeBlock
fromPath path =
    LifeBlock path Array.empty


dragNewBlock : Model a -> LifeBlock -> ( Model a, Int )
dragNewBlock model block =
    let
        ( bumpedModel, id ) =
            nextBlockId model

        blocks =
            Dict.insert id block model.blocks
    in
    ( { bumpedModel | blocks = blocks }, id )


nextBlockId : Model a -> ( Model a, Int )
nextBlockId model =
    ( { model | nextBlockId = model.nextBlockId + 1 }
    , model.nextBlockId
    )
