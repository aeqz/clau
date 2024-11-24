port module Ports exposing
    ( encodeAndSave, saved
    , loadFromInput, loadedAndDecoded
    , draggingFile, fileDropped, loadDropped
    )

{-|


# Save

@docs encodeAndSave, saved


# Load

@docs loadFromInput, loadedAndDecoded


# Drag & Drop

@docs draggingFile, fileDropped, loadDropped

-}

import Json.Decode as D exposing (Decoder)
import Json.Encode as E



-- SAVE


port save :
    { name : String
    , data : E.Value
    , password : String
    }
    -> Cmd msg


port saved : (Bool -> msg) -> Sub msg


encodeAndSave :
    (a -> E.Value)
    ->
        { name : String
        , data : a
        , password : String
        }
    -> Cmd msg
encodeAndSave encode { name, data, password } =
    save
        { name = name
        , data = encode data
        , password = password
        }



-- LOAD


port loadFromInput :
    { inputId : String
    , password : String
    }
    -> Cmd msg


port loaded : (E.Value -> msg) -> Sub msg


loadedAndDecoded : Decoder a -> (Result D.Error (Maybe a) -> msg) -> Sub msg
loadedAndDecoded decoder toMsg =
    D.oneOf
        [ D.null Nothing
        , D.map Just decoder
        ]
        |> D.decodeValue
        |> loaded
        |> Sub.map toMsg



-- Drag & Drop


port draggingFile : (Bool -> msg) -> Sub msg


port fileDropped : (Maybe String -> msg) -> Sub msg


port loadDropped : { password : String } -> Cmd msg
