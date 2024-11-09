module Model.Keys exposing
    ( Keys, encodeKeys, keysDecoder
    , Key, emptyKey, encodeKey, keyDecoder
    )

{-|


# Keys

@docs Keys, encodeKeys, keysDecoder


# Key

@docs Key, emptyKey, encodeKey, keyDecoder

-}

import Array exposing (Array)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E exposing (Value)



-- KEYS


type alias Keys =
    Array Key


encodeKeys : Keys -> Value
encodeKeys keys =
    E.object
        [ ( "version", E.string "V1" )
        , ( "keys", E.array encodeKey keys )
        ]


keysDecoder : Decoder Keys
keysDecoder =
    D.field "version" versionDecoder
        |> D.andThen
            (D.field "keys" << D.array << keyDecoder)



-- KEY


type alias Key =
    { name : String
    , url : String
    , user : String
    , password : String
    , notes : String
    }


emptyKey : Key
emptyKey =
    { name = ""
    , url = ""
    , user = ""
    , password = ""
    , notes = ""
    }


encodeKey : Key -> Value
encodeKey { name, url, user, password, notes } =
    E.object
        [ ( "name", E.string name )
        , ( "url", E.string url )
        , ( "user", E.string user )
        , ( "password", E.string password )
        , ( "notes", E.string notes )
        ]


keyDecoder : Version -> Decoder Key
keyDecoder version =
    case version of
        V1 ->
            D.map5 Key
                (D.field "name" D.string)
                (D.field "url" D.string)
                (D.field "user" D.string)
                (D.field "password" D.string)
                (D.field "notes" D.string)



-- VERSIONING


type Version
    = V1


versionDecoder : Decoder Version
versionDecoder =
    D.string
        |> D.andThen
            (\version ->
                case version of
                    "V1" ->
                        D.succeed V1

                    _ ->
                        D.fail ("Unknown version \"" ++ version ++ "\"")
            )
