module UI.Events exposing (onEscape)

import Browser.Events as BE
import Json.Decode as D


onEscape : msg -> Sub msg
onEscape msg =
    BE.onKeyDown <|
        D.andThen
            (\key ->
                if key == "Escape" then
                    D.succeed msg

                else
                    D.fail "Not the escape key"
            )
        <|
            D.field "key" D.string
