module Main exposing (main)

import Browser exposing (Document)
import Html
import Pages.Loaded as Loaded
import Pages.NotLoaded as NotLoaded
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
    { literals : Literals
    , page : Page
    }


type Page
    = NotLoaded NotLoaded.Model
    | Loaded Loaded.Model


init : Flags -> ( Model, Cmd msg )
init { literals } =
    ( { literals = literals
      , page = NotLoaded NotLoaded.init
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NotLoadedMsg NotLoaded.Msg
    | LoadedMsg Loaded.Msg


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        NotLoaded notLoaded ->
            NotLoaded.subscriptions notLoaded
                |> Sub.map NotLoadedMsg

        Loaded loaded ->
            Loaded.subscriptions loaded
                |> Sub.map LoadedMsg


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        NotLoadedMsg notLoadedMsg ->
            case model.page of
                Loaded _ ->
                    ( model, Cmd.none )

                NotLoaded notLoaded ->
                    NotLoaded.update notLoadedMsg notLoaded
                        |> handleNotLoaded model

        LoadedMsg loadedMsg ->
            case model.page of
                NotLoaded _ ->
                    ( model, Cmd.none )

                Loaded loaded ->
                    Loaded.update loadedMsg loaded
                        |> handleLoaded model


handleNotLoaded : Model -> ( NotLoaded.Model, NotLoaded.Effect msg ) -> ( Model, Cmd msg )
handleNotLoaded model ( notLoaded, effect ) =
    case effect of
        NotLoaded.Cmd cmd ->
            ( { model | page = NotLoaded notLoaded }, cmd )

        NotLoaded.NewKeys ->
            ( { model | page = Loaded Loaded.new }, Cmd.none )

        NotLoaded.Loaded file ->
            ( { model | page = Loaded (Loaded.fromFile file) }, Cmd.none )


handleLoaded : Model -> ( Loaded.Model, Loaded.Effect msg ) -> ( Model, Cmd msg )
handleLoaded model ( loaded, effect ) =
    case effect of
        Loaded.Cmd cmd ->
            ( { model | page = Loaded loaded }, cmd )

        Loaded.Close ->
            ( { model | page = NotLoaded NotLoaded.init }, Cmd.none )



-- VIEW


view : Model -> Document Msg
view model =
    case model.page of
        NotLoaded notLoaded ->
            { title = NotLoaded.title
            , body =
                NotLoaded.view model.literals notLoaded
                    |> List.map (Html.map NotLoadedMsg)
            }

        Loaded loaded ->
            { title = Loaded.title loaded
            , body =
                Loaded.view model.literals loaded
                    |> List.map (Html.map LoadedMsg)
            }
