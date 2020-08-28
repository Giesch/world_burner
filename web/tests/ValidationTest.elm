module ValidationTest exposing (..)

import Api
import ExampleLifepathJson as Example
import Expect exposing (Expectation)
import Json.Decode as Decode
import LifeBlock exposing (LifeBlock)
import LifeBlock.Validation as Validation
import Lifepath exposing (Lifepath)
import List.NonEmpty as NonEmpty exposing (NonEmpty)
import Test exposing (..)


bornTests : Test
bornTests =
    describe "born lifepath rules"
        [ test "a character has to be born" <|
            \_ ->
                withLifepath "prince" <|
                    \prince ->
                        prince
                            |> NonEmpty.singleton
                            |> Validation.warnings
                            |> List.map Validation.reason
                            |> List.member Validation.MissingBorn
                            |> Expect.true "Expected prince to need a born lifepath"
        , test "a born lifepath cannot come after another lifepath" <|
            \_ ->
                withLifepaths ( "prince", "born noble" ) <|
                    \( prince, bornNoble ) ->
                        let
                            actual : List Validation.Error
                            actual =
                                Validation.errors
                                    (NonEmpty.singleton prince)
                                    (NonEmpty.singleton bornNoble)
                        in
                        Expect.equal actual
                            [ Validation.Error
                                "Only a character's first lifepath may be a 'born' lifepath"
                            ]
        ]


requirementsTest : Test
requirementsTest =
    test "unmet requirements with a born lifepath is an error" <|
        \_ ->
            withLifepaths ( "prince", "born noble" ) <|
                \( prince, bornNoble ) ->
                    let
                        actual : List Validation.Error
                        actual =
                            Validation.errors
                                (NonEmpty.singleton bornNoble)
                                (NonEmpty.singleton prince)
                    in
                    Expect.equal actual
                        [ Validation.Error
                            "Prince requires Born Noble and Noble Axe Bearer"
                        ]


withLifepath : String -> (Lifepath -> Expectation) -> Expectation
withLifepath =
    testWith getPath


getPath : String -> Result String Lifepath
getPath name =
    dwarves
        |> Result.map (List.filter (\lp -> lp.name == name))
        |> Result.andThen
            (\ds ->
                case List.head ds of
                    Just d ->
                        Ok d

                    Nothing ->
                        Err "Lifepath not found"
            )


withLifepaths :
    ( String, String )
    -> (( Lifepath, Lifepath ) -> Expectation)
    -> Expectation
withLifepaths =
    testWith getLifePaths


getLifePaths : ( String, String ) -> Result String ( Lifepath, Lifepath )
getLifePaths ( first, second ) =
    let
        pair : Result String ( Maybe Lifepath, Maybe Lifepath )
        pair =
            dwarves
                |> Result.map (\ds -> ( lookup first ds, lookup second ds ))
    in
    case pair of
        Ok ( Just left, Just right ) ->
            Ok ( left, right )

        Ok ( Nothing, Just _ ) ->
            Err <| "Lifepath not found: " ++ first

        Ok ( Just _, Nothing ) ->
            Err <| "Lifepath not found: " ++ second

        Ok ( Nothing, Nothing ) ->
            Err "Lifepaths not found"

        Err err ->
            Err err


lookup : String -> List Lifepath -> Maybe Lifepath
lookup name ds =
    ds
        |> List.filter (\lp -> lp.name == name)
        |> List.head


testWith : (k -> Result String v) -> k -> (v -> Expectation) -> Expectation
testWith getter key test =
    okAndThen test (getter key)


okAndThen : (a -> Expectation) -> Result String a -> Expectation
okAndThen test res =
    case res of
        Ok val ->
            test val

        Err err ->
            Expect.fail err


dwarves : Result String (List Lifepath)
dwarves =
    Example.dwarves
        |> Decode.decodeString Api.lifepathsDecoder
        |> Result.mapError Decode.errorToString
