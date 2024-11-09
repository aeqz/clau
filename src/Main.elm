module Main exposing (main)

import Browser exposing (Document)
import UI.Literals exposing (Literals)


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Flags =
    { literals : Literals }


type alias Model =
    { literals : Literals }


init : Flags -> ( Model, Cmd msg )
init { literals } =
    ( { literals = literals }
    , Cmd.none
    )



-- UPDATE


type alias Msg =
    Never


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg _ =
    never msg



-- VIEW


view : Model -> Document Msg
view _ =
    { title = "Clau"
    , body =
        []
    }
