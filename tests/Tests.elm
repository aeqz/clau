module Tests exposing (suite)

import Array
import Expect
import Json.Decode as D
import Model.Keys as Keys
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Encode and decode keys" <|
        let
            keys =
                Array.fromList
                    [ { name = "Name"
                      , url = "htpps://clau.com"
                      , user = "aeqz"
                      , password = "1234"
                      , notes = "Hello\nNotes"
                      }
                    ]
        in
        [ test "Can decode encoded keys" <|
            \_ ->
                Keys.encodeKeys keys
                    |> D.decodeValue Keys.keysDecoder
                    |> Expect.equal (Ok keys)
        , test "Can decode a V1 snapshot" <|
            \_ ->
                "{\"version\":\"V1\",\"keys\":[{\"name\":\"Name\",\"url\":\"htpps://clau.com\",\"user\":\"aeqz\",\"password\":\"1234\",\"notes\":\"Hello\\nNotes\"}]}"
                    |> D.decodeString Keys.keysDecoder
                    |> Expect.equal (Ok keys)
        ]
