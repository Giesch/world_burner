module LifeBlock exposing
    ( LifeBlock
    , add
    , addBatch
    )

import Array exposing (Array)
import Dict exposing (Dict)
import Lifepath exposing (Lifepath)


type alias LifeBlock =
    { first : Lifepath
    , rest : Array Lifepath
    , beaconId : Int
    }


type alias Model a =
    -- TODO should this be an opaque submodel managed by this module?
    { a
        | nextBeaconId : Int
        , blocks : Dict Int LifeBlock
    }


addBatch : Model a -> List Lifepath -> ( Model a, List LifeBlock )
addBatch ({ nextBeaconId, blocks } as model) lifepaths =
    let
        makeBlock : Lifepath -> ( Int, List LifeBlock ) -> ( Int, List LifeBlock )
        makeBlock path ( nextId, blockList ) =
            ( nextId + 1, LifeBlock path Array.empty nextId :: blockList )

        ( newNextId, blocksWithIds ) =
            List.foldl makeBlock ( nextBeaconId, [] ) lifepaths

        insertBlock : LifeBlock -> Dict Int LifeBlock -> Dict Int LifeBlock
        insertBlock block dict =
            Dict.insert block.beaconId block dict

        newBlocks : Dict Int LifeBlock
        newBlocks =
            List.foldl insertBlock blocks blocksWithIds
    in
    ( { model | nextBeaconId = newNextId, blocks = newBlocks }
    , List.reverse blocksWithIds
    )


add : Model a -> Lifepath -> ( Model a, Int )
add model path =
    let
        ( bumpedModel, id ) =
            bump model

        blocks =
            Dict.insert id (LifeBlock path Array.empty id) model.blocks
    in
    ( { bumpedModel | blocks = blocks }, id )


bump : Model a -> ( Model a, Int )
bump model =
    ( { model | nextBeaconId = model.nextBeaconId + 1 }
    , model.nextBeaconId
    )
