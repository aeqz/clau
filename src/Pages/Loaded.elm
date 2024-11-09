module Pages.Loaded exposing
    ( Model, FileSaving, SavingError, new, fromFile
    , Msg, Effect(..), subscriptions, update
    , title, view
    )

{-|


# Model

@docs Model, FileSaving, SavingError, new, fromFile


# Update

@docs Msg, Effect, subscriptions, update


# View

title, view

-}

import Array
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Model.Keys as Keys exposing (Key, Keys)
import Ports
import UI.Events as Events
import UI.Literals exposing (Literals)



-- INIT


new : Model
new =
    { keys = Array.fromList [ Keys.emptyKey ]
    , file = Nothing
    , fileSaving = Nothing
    , selectedKey =
        Just
            { index = 0
            , passwordVisible = False
            }
    }


fromFile : { keys : Keys, name : String, password : String } -> Model
fromFile { keys, name, password } =
    { keys = keys
    , fileSaving = Nothing
    , selectedKey = Nothing
    , file =
        Just
            { name = name
            , password = password
            }
    }


type alias Model =
    { keys : Keys
    , file : Maybe { name : String, password : String }
    , fileSaving : Maybe FileSaving
    , selectedKey : Maybe SelectedKey
    }


type alias SelectedKey =
    { index : Int
    , passwordVisible : Bool
    }


type alias FileSaving =
    { name : String
    , password : String
    , passwordConfirm : String
    , saving : Result SavingError Bool
    , original : Maybe { keep : Bool, password : String }
    }


type SavingError
    = PasswordsDoNotMatch
    | CouldNotSave



-- UPDATE


type Msg
    = CloseKeys
    | SaveKeys
    | CloseFileSaving
    | FileSavingMsg FileSavingMsg
    | AddNewKey
    | DeleteKey Int
    | SelectKey Int
    | PasswordVisible Int Bool
    | CloseSelectedKey
    | KeyMsg KeyMsg


type FileSavingMsg
    = SaveNameInput String
    | SavePasswordInput String
    | SavePasswordConfirmInput String
    | KeepOriginalPasswordInput Bool
    | SaveFile
    | SavingError SavingError


type KeyMsg
    = KeyNameInput String
    | KeyUrlInput String
    | KeyUserInput String
    | KeyPasswordInput String
    | KeyNotesInput String


type Effect msg
    = Cmd (Cmd msg)
    | Close


subscriptions : Model -> Sub Msg
subscriptions { fileSaving, selectedKey } =
    case fileSaving of
        Nothing ->
            case selectedKey of
                Nothing ->
                    Sub.none

                Just _ ->
                    Events.onEscape CloseSelectedKey

        Just _ ->
            Sub.batch
                [ Events.onEscape CloseFileSaving
                , Ports.saved <|
                    \saved ->
                        if saved then
                            CloseFileSaving

                        else
                            FileSavingMsg <| SavingError CouldNotSave
                ]


update : Msg -> Model -> ( Model, Effect msg )
update msg model =
    case msg of
        CloseKeys ->
            ( model, Close )

        SaveKeys ->
            ( { model
                | fileSaving =
                    Just <|
                        case model.file of
                            Nothing ->
                                { name = "Nova.clau"
                                , password = ""
                                , passwordConfirm = ""
                                , saving = Ok False
                                , original = Nothing
                                }

                            Just { name, password } ->
                                { name = name
                                , password = ""
                                , passwordConfirm = ""
                                , saving = Ok False
                                , original =
                                    Just
                                        { keep = True
                                        , password = password
                                        }
                                }
              }
            , Cmd Cmd.none
            )

        CloseFileSaving ->
            ( { model | fileSaving = Nothing }, Cmd Cmd.none )

        FileSavingMsg fileSavingMsg ->
            model.fileSaving
                |> Maybe.map (updateFileSaving model.keys fileSavingMsg)
                |> Maybe.map
                    (Tuple.mapFirst
                        (\fileSaving ->
                            { model | fileSaving = Just fileSaving }
                        )
                    )
                |> Maybe.withDefault ( model, Cmd Cmd.none )

        AddNewKey ->
            ( { model
                | keys = Array.push Keys.emptyKey model.keys
                , selectedKey =
                    Just
                        { index = Array.length model.keys
                        , passwordVisible = False
                        }
              }
            , Cmd Cmd.none
            )

        DeleteKey index ->
            ( { model
                | selectedKey = Nothing
                , keys =
                    Array.append
                        (Array.slice 0 index model.keys)
                        (Array.slice (index + 1) (Array.length model.keys) model.keys)
              }
            , Cmd Cmd.none
            )

        SelectKey index ->
            case Array.get index model.keys of
                Nothing ->
                    ( model, Cmd Cmd.none )

                Just _ ->
                    ( { model
                        | selectedKey =
                            Just
                                { index = index
                                , passwordVisible = False
                                }
                      }
                    , Cmd Cmd.none
                    )

        PasswordVisible index passwordVisible ->
            case model.selectedKey of
                Just selectedKey ->
                    if selectedKey.index == index then
                        ( { model
                            | selectedKey =
                                Just
                                    { selectedKey
                                        | passwordVisible = passwordVisible
                                    }
                          }
                        , Cmd Cmd.none
                        )

                    else
                        ( model, Cmd Cmd.none )

                Nothing ->
                    ( model, Cmd Cmd.none )

        CloseSelectedKey ->
            case model.selectedKey of
                Nothing ->
                    ( model, Cmd Cmd.none )

                Just { index } ->
                    if Array.get index model.keys == Just Keys.emptyKey then
                        ( { model
                            | selectedKey = Nothing
                            , keys =
                                Array.append
                                    (Array.slice 0 index model.keys)
                                    (Array.slice (index + 1) (Array.length model.keys) model.keys)
                          }
                        , Cmd Cmd.none
                        )

                    else
                        ( { model | selectedKey = Nothing }, Cmd Cmd.none )

        KeyMsg keyMsg ->
            case model.selectedKey of
                Nothing ->
                    ( model, Cmd Cmd.none )

                Just { index } ->
                    ( { model
                        | keys =
                            Array.get index model.keys
                                |> Maybe.map
                                    (\key ->
                                        Array.set index (updateKey keyMsg key) model.keys
                                    )
                                |> Maybe.withDefault model.keys
                      }
                    , Cmd Cmd.none
                    )


updateFileSaving : Keys -> FileSavingMsg -> FileSaving -> ( FileSaving, Effect msg )
updateFileSaving keys msg model =
    case msg of
        SaveNameInput name ->
            ( { model | name = name }, Cmd Cmd.none )

        SavePasswordInput password ->
            ( { model | password = password }, Cmd Cmd.none )

        SavePasswordConfirmInput passwordConfirm ->
            ( { model | passwordConfirm = passwordConfirm }, Cmd Cmd.none )

        KeepOriginalPasswordInput keep ->
            ( { model
                | original =
                    model.original
                        |> Maybe.map
                            (\original ->
                                { original | keep = keep }
                            )
              }
            , Cmd Cmd.none
            )

        SaveFile ->
            case
                Maybe.andThen
                    (\{ keep, password } ->
                        if keep then
                            Just password

                        else
                            Nothing
                    )
                    model.original
            of
                Just password ->
                    ( { model | saving = Ok True }
                    , Cmd <|
                        Ports.encodeAndSave Keys.encodeKeys
                            { name = model.name
                            , password = password
                            , data = keys
                            }
                    )

                Nothing ->
                    if model.password == model.passwordConfirm then
                        ( { model | saving = Ok True }
                        , Cmd <|
                            Ports.encodeAndSave Keys.encodeKeys
                                { name = model.name
                                , password = model.password
                                , data = keys
                                }
                        )

                    else
                        ( { model | saving = Err PasswordsDoNotMatch }
                        , Cmd Cmd.none
                        )

        SavingError savingError ->
            ( { model | saving = Err savingError }, Cmd Cmd.none )


updateKey : KeyMsg -> Key -> Key
updateKey msg model =
    case msg of
        KeyNameInput name ->
            { model | name = name }

        KeyUrlInput url ->
            { model | url = url }

        KeyUserInput user ->
            { model | user = user }

        KeyPasswordInput password ->
            { model | password = password }

        KeyNotesInput notes ->
            { model | notes = notes }



-- VIEW


title : Model -> String
title { file } =
    String.append "Clau • " <|
        case file of
            Nothing ->
                "Nova"

            Just { name } ->
                name


view : Literals -> Model -> List (Html Msg)
view literals { keys, selectedKey, fileSaving } =
    [ H.main_
        [ A.class "main vertical centered" ]
        [ H.div
            (A.class "horizontal full-size"
                :: (if fileSaving == Nothing then
                        []

                    else
                        [ A.attribute "inert" "" ]
                   )
            )
            [ H.div
                (A.class "sidebar vertical full-height"
                    :: (if selectedKey == Nothing then
                            []

                        else
                            [ A.attribute "data-secondary" "" ]
                       )
                )
                [ H.div
                    [ A.class "horizontal" ]
                    [ H.button
                        [ E.onClick CloseKeys
                        , A.class "button"
                        ]
                        [ H.text literals.closeKeys ]
                    , H.button
                        [ E.onClick SaveKeys
                        , A.class "button"
                        ]
                        [ H.text literals.saveKeys ]
                    ]
                , H.ul
                    [ A.class "list full-height" ]
                    (Array.indexedMap
                        (\index { name } ->
                            H.li
                                (if Just index == Maybe.map .index selectedKey then
                                    [ A.attribute "data-selected" "" ]

                                 else
                                    []
                                )
                                [ H.button
                                    [ E.onClick <| SelectKey index ]
                                    [ H.text <|
                                        if String.isEmpty name then
                                            literals.newKey

                                        else
                                            name
                                    ]
                                ]
                        )
                        keys
                        |> Array.toList
                    )
                , H.div
                    []
                    [ H.button
                        [ E.onClick AddNewKey
                        , A.class "button"
                        ]
                        [ H.text literals.addKey ]
                    ]
                ]
            , case selectedKey of
                Nothing ->
                    H.div
                        [ A.class "vertical" ]
                        []

                Just { index, passwordVisible } ->
                    case Array.get index keys of
                        Nothing ->
                            H.div
                                [ A.class "vertical" ]
                                []

                        Just { name, url, user, password, notes } ->
                            H.div
                                [ A.class "form vertical" ]
                                [ H.div
                                    [ A.class "horizontal" ]
                                    [ H.label
                                        [ A.for "edit-key__name" ]
                                        [ H.text literals.name ]
                                    , H.input
                                        [ A.id "edit-key__name"
                                        , A.type_ "text"
                                        , A.value name
                                        , E.onInput <|
                                            KeyMsg
                                                << KeyNameInput
                                        ]
                                        []
                                    ]
                                , H.div
                                    [ A.class "horizontal" ]
                                    [ H.label
                                        [ A.for "edit-key__url" ]
                                        [ H.text literals.url ]
                                    , H.input
                                        [ A.id "edit-key__url"
                                        , A.type_ "text"
                                        , A.value url
                                        , E.onInput <|
                                            KeyMsg
                                                << KeyUrlInput
                                        ]
                                        []
                                    ]
                                , H.div
                                    [ A.class "horizontal" ]
                                    [ H.label
                                        [ A.for "edit-key__user" ]
                                        [ H.text literals.user ]
                                    , H.input
                                        [ A.id "edit-key__user"
                                        , A.type_ "text"
                                        , A.value user
                                        , E.onInput <|
                                            KeyMsg
                                                << KeyUserInput
                                        ]
                                        []
                                    ]
                                , H.div
                                    [ A.class "horizontal" ]
                                    [ H.label
                                        [ A.for "edit-key__password" ]
                                        [ H.text literals.password ]
                                    , H.input
                                        [ A.id "edit-key__password"
                                        , A.type_ <|
                                            if passwordVisible then
                                                "text"

                                            else
                                                "password"
                                        , A.value password
                                        , E.onBlur <| PasswordVisible index False
                                        , E.onFocus <| PasswordVisible index True
                                        , E.onInput <|
                                            KeyMsg
                                                << KeyPasswordInput
                                        ]
                                        []
                                    ]
                                , H.div
                                    [ A.class "horizontal" ]
                                    [ H.label
                                        [ A.for "edit-key__notes" ]
                                        [ H.text literals.notes ]
                                    , H.textarea
                                        [ A.id "edit-key__notes"
                                        , A.value notes
                                        , E.onInput <|
                                            KeyMsg
                                                << KeyNotesInput
                                        ]
                                        []
                                    ]
                                , H.div
                                    [ A.class "horizontal" ]
                                    [ H.button
                                        [ E.onClick CloseSelectedKey
                                        , A.class "button"
                                        ]
                                        [ H.text literals.closeKey ]
                                    , H.button
                                        [ E.onClick <| DeleteKey index
                                        , A.class "button"
                                        ]
                                        [ H.text literals.deleteKey ]
                                    ]
                                ]
            ]
        , Maybe.map (viewFileSavingModal literals) fileSaving
            |> Maybe.withDefault (H.node "dialog" [] [])
        ]
    ]


viewFileSavingModal : Literals -> FileSaving -> Html Msg
viewFileSavingModal literals { name, password, passwordConfirm, saving, original } =
    H.node "dialog"
        [ A.class "modal"
        , A.attribute "open" ""
        ]
        [ H.form
            [ A.class "form vertical"
            , E.onSubmit <|
                FileSavingMsg SaveFile
            ]
            [ H.div
                [ A.class "horizontal" ]
                [ H.label
                    [ A.for "save-keys__name" ]
                    [ H.text literals.name ]
                , H.input
                    [ A.id "save-keys__name"
                    , A.type_ "text"
                    , A.value name
                    , E.onInput <|
                        FileSavingMsg
                            << SaveNameInput
                    ]
                    []
                ]
            , if Maybe.map .keep original == Just True then
                H.text ""

              else
                H.div
                    [ A.class "horizontal" ]
                    [ H.label
                        [ A.for "save-keys__password" ]
                        [ H.text literals.password ]
                    , H.input
                        [ A.id "save-keys__password"
                        , A.type_ "password"
                        , A.value password
                        , E.onInput <|
                            FileSavingMsg
                                << SavePasswordInput
                        ]
                        []
                    ]
            , if Maybe.map .keep original == Just True then
                H.text ""

              else
                H.div
                    [ A.class "horizontal" ]
                    [ H.label
                        [ A.for "save-keys__password-confirm" ]
                        [ H.text literals.confirmPassword ]
                    , H.input
                        [ A.id "save-keys__password-confirm"
                        , A.type_ "password"
                        , A.value passwordConfirm
                        , E.onInput <|
                            FileSavingMsg
                                << SavePasswordConfirmInput
                        ]
                        []
                    ]
            , case original of
                Nothing ->
                    H.text ""

                Just { keep } ->
                    H.div
                        [ A.class "horizontal" ]
                        [ H.input
                            [ A.id "save-keys__new-password"
                            , A.type_ "checkbox"
                            , A.value password
                            , A.checked <| not keep
                            , E.onInput <|
                                FileSavingMsg
                                    << KeepOriginalPasswordInput
                                    << (==) "keep"
                            , A.value
                                (if keep then
                                    "new"

                                 else
                                    "keep"
                                )
                            ]
                            []
                        , H.label
                            [ A.for "save-keys__new-password" ]
                            [ H.text literals.newPassword ]
                        ]
            , case saving of
                Ok _ ->
                    H.text ""

                Err error ->
                    H.p
                        [ A.class "error" ]
                        [ H.text <|
                            case error of
                                CouldNotSave ->
                                    literals.couldNotSaveFile

                                PasswordsDoNotMatch ->
                                    literals.paswordsDoNotMatch
                        ]
            , H.div
                [ A.class "horizontal" ]
                [ H.button
                    [ A.type_ "submit"
                    , A.class "button"
                    , A.disabled <| saving == Ok True
                    ]
                    [ H.text literals.save ]
                , H.button
                    [ A.type_ "button"
                    , A.class "button"
                    , E.onClick CloseFileSaving
                    ]
                    [ H.text literals.cancel ]
                ]
            ]
        ]
