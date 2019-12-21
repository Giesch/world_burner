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


type alias Model a b =
    { a
        | nextBeaconId : Int
        , beacons : Dict Int b
    }


addBatch :
    Model a b
    -> List Lifepath
    -> (LifeBlock -> b)
    -> ( Model a b, List LifeBlock )
addBatch ({ nextBeaconId, beacons } as model) lifepaths constructor =
    let
        makeBlock : Lifepath -> ( Int, List LifeBlock ) -> ( Int, List LifeBlock )
        makeBlock path ( nextId, blockList ) =
            ( nextId + 1, LifeBlock path Array.empty nextId :: blockList )

        ( newNextId, blocksWithIds ) =
            List.foldl makeBlock ( nextBeaconId, [] ) lifepaths

        insertBlock : LifeBlock -> Dict Int b -> Dict Int b
        insertBlock block dict =
            Dict.insert block.beaconId (constructor block) dict

        newBlocks : Dict Int b
        newBlocks =
            List.foldl insertBlock beacons blocksWithIds
    in
    ( { model | nextBeaconId = newNextId, beacons = newBlocks }
    , List.reverse blocksWithIds
    )


add : Model a b -> Lifepath -> (LifeBlock -> b) -> ( Model a b, Int )
add model path constructor =
    let
        ( bumpedModel, id ) =
            bump model

        beacons =
            Dict.insert id
                (constructor <| LifeBlock path Array.empty id)
                model.beacons
    in
    ( { bumpedModel | beacons = beacons }, id )


bump : Model a b -> ( Model a b, Int )
bump model =
    ( { model | nextBeaconId = model.nextBeaconId + 1 }
    , model.nextBeaconId
    )
