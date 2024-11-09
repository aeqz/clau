module Pages.NotLoaded exposing
    ( Model, FileSource, LoadingError, init
    , Msg, Effect(..), subscriptions, update
    , title, view
    )

{-|


# Model

@docs Model, FileSource, LoadingError, init


# Update

@docs Msg, Effect, subscriptions, update


# View

title, view

-}

import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Json.Decode as D
import Model.Keys as Keys exposing (Keys)
import Ports
import UI.Events as Events
import UI.Icons as Icons
import UI.Literals exposing (Literals)



-- MODEL


init : Model
init =
    { fileLoading = Nothing
    , draggingFile = False
    }


type alias Model =
    { fileLoading : Maybe FileLoading
    , draggingFile : Bool
    }


type alias FileLoading =
    { file : String
    , source : FileSource
    , password : String
    , loading : Result LoadingError Bool
    }


type FileSource
    = InputFile { inputId : String }
    | DroppedFile


type LoadingError
    = WrongPassword
    | DecodeError D.Error



-- UPDATE


type Msg
    = CreateNewKeys
    | FileInput String String
    | DraggingFile Bool
    | FileDropped (Maybe String)
    | CancelFileSelection
    | FileLoadingMsg FileLoadingMsg


type FileLoadingMsg
    = LoadPaswordInput String
    | LoadKeys { source : FileSource }
    | LoadingError LoadingError
    | KeysLoaded
        { keys : Keys
        , name : String
        , password : String
        }


type Effect msg
    = Cmd (Cmd msg)
    | NewKeys
    | Loaded
        { keys : Keys
        , name : String
        , password : String
        }


subscriptions : Model -> Sub Msg
subscriptions { fileLoading } =
    case fileLoading of
        Nothing ->
            Sub.batch
                [ Ports.draggingFile DraggingFile
                , Ports.fileDropped FileDropped
                ]

        Just { file, password } ->
            Sub.batch
                [ Events.onEscape CancelFileSelection
                , Ports.fileDropped FileDropped
                , Ports.loadedAndDecoded Keys.keysDecoder
                    (\result ->
                        case result of
                            Err error ->
                                FileLoadingMsg <|
                                    LoadingError <|
                                        DecodeError error

                            Ok Nothing ->
                                FileLoadingMsg <|
                                    LoadingError WrongPassword

                            Ok (Just keys) ->
                                FileLoadingMsg <|
                                    KeysLoaded
                                        { keys = keys
                                        , name = cleanfileName file
                                        , password = password
                                        }
                    )
                ]


update : Msg -> Model -> ( Model, Effect msg )
update msg model =
    case msg of
        CreateNewKeys ->
            ( model, NewKeys )

        FileInput inputId file ->
            ( { model
                | fileLoading =
                    Just
                        { file = file
                        , source = InputFile { inputId = inputId }
                        , loading = Ok False
                        , password = ""
                        }
              }
            , Cmd Cmd.none
            )

        DraggingFile draggingFile ->
            ( { model | draggingFile = draggingFile }, Cmd Cmd.none )

        FileDropped maybeFile ->
            ( { model
                | fileLoading =
                    Maybe.map
                        (\file ->
                            { file = file
                            , source = DroppedFile
                            , loading = Ok False
                            , password = ""
                            }
                        )
                        maybeFile
              }
            , Cmd Cmd.none
            )

        CancelFileSelection ->
            ( { model | fileLoading = Nothing }, Cmd Cmd.none )

        FileLoadingMsg fileLoadingMsg ->
            model.fileLoading
                |> Maybe.map (updateFileLoading fileLoadingMsg)
                |> Maybe.map (Tuple.mapFirst Just)
                |> Maybe.map
                    (Tuple.mapFirst
                        (\fileLoading ->
                            { model | fileLoading = fileLoading }
                        )
                    )
                |> Maybe.withDefault ( model, Cmd Cmd.none )


updateFileLoading : FileLoadingMsg -> FileLoading -> ( FileLoading, Effect msg )
updateFileLoading msg model =
    case msg of
        LoadPaswordInput password ->
            ( { model | password = password }, Cmd Cmd.none )

        LoadKeys { source } ->
            ( { model | loading = Ok True }
            , Cmd <|
                case source of
                    DroppedFile ->
                        Ports.loadDropped { password = model.password }

                    InputFile { inputId } ->
                        Ports.loadFromInput
                            { inputId = inputId
                            , password = model.password
                            }
            )

        LoadingError loadingError ->
            ( { model | loading = Err loadingError }, Cmd Cmd.none )

        KeysLoaded loaded ->
            ( model, Loaded loaded )



-- VIEW


title : String
title =
    "Clau"


view : Literals -> Model -> List (Html Msg)
view literals { fileLoading, draggingFile } =
    [ H.main_
        [ A.class "main vertical centered" ]
        [ H.div
            (A.class "vertical end-align"
                :: (if fileLoading == Nothing && not draggingFile then
                        []

                    else
                        [ A.attribute "inert" "" ]
                   )
            )
            [ H.div
                (A.class "upload-panel"
                    :: (if draggingFile then
                            [ A.attribute "data-dragging-file" "" ]

                        else
                            []
                       )
                )
                [ H.label
                    [ A.for "load-keys__file" ]
                    [ H.text literals.loadKeysFile
                    , Icons.upload
                    ]
                , H.input
                    [ A.id "load-keys__file"
                    , A.type_ "file"
                    , A.value <|
                        case fileLoading of
                            Nothing ->
                                ""

                            Just { file, source } ->
                                if source == InputFile { inputId = "load-keys__file" } then
                                    file

                                else
                                    ""
                    , E.onInput <|
                        FileInput "load-keys__file"
                    ]
                    []
                ]
            , H.button
                [ A.class "text-button"
                , E.onClick CreateNewKeys
                ]
                [ H.text literals.orCreateNewKeys ]
            ]
        , Maybe.map (viewFileLoadingModal literals) fileLoading
            |> Maybe.withDefault (H.node "dialog" [] [])
        ]
    ]


viewFileLoadingModal : Literals -> FileLoading -> Html Msg
viewFileLoadingModal literals { file, source, password, loading } =
    H.node "dialog"
        [ A.class "modal"
        , A.attribute "open" ""
        ]
        [ H.form
            [ A.class "form vertical"
            , E.onSubmit <|
                FileLoadingMsg <|
                    LoadKeys { source = source }
            ]
            [ H.div
                [ A.class "vertical" ]
                [ H.label
                    [ A.for "load-keys__password" ]
                    [ H.text <|
                        String.join " "
                            [ literals.passwordForOpening
                            , cleanfileName file
                            ]
                    ]
                , H.input
                    [ A.id "load-keys__password"
                    , A.type_ "password"
                    , A.value password
                    , E.onInput <|
                        FileLoadingMsg
                            << LoadPaswordInput
                    ]
                    []
                ]
            , case loading of
                Err error ->
                    H.p
                        [ A.class "error" ]
                        [ H.text <|
                            case error of
                                WrongPassword ->
                                    literals.wrongPassword

                                DecodeError _ ->
                                    literals.corruptedFile
                        ]

                Ok _ ->
                    H.text ""
            , H.div
                [ A.class "horizontal" ]
                [ H.button
                    [ A.type_ "submit"
                    , A.class "button"
                    , A.disabled <| loading == Ok True
                    ]
                    [ H.text literals.open ]
                , H.button
                    [ A.type_ "button"
                    , A.class "button"
                    , E.onClick CancelFileSelection
                    ]
                    [ H.text literals.cancel ]
                ]
            ]
        ]


cleanfileName : String -> String
cleanfileName =
    let
        prefix =
            "C:\\fakepath\\"

        prefixLength =
            String.length prefix
    in
    \file ->
        if String.startsWith prefix file then
            String.dropLeft prefixLength file

        else
            file
