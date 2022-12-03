module Effect.View exposing (Msg, update, viewEffects)

import Dict
import Effect
import Effect.Types
import FeatherIcons
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D


type Msg
    = SetType Int (Maybe Effect.Type)
    | SetParam Int String Int
    | AddEffect
    | RemoveEffect


replace : Int -> (a -> a) -> List a -> List a
replace idx f list =
    List.indexedMap
        (\i v ->
            if i == idx then
                f v

            else
                v
        )
        list


update : Msg -> List Effect.Instance -> List Effect.Instance
update msg effects =
    case msg of
        SetType idx maybeNewType ->
            case maybeNewType of
                Just newType ->
                    replace idx (\_ -> { type_ = newType, values = Effect.defaultValues newType }) effects

                Nothing ->
                    effects

        SetParam idx paramId newValue ->
            replace idx (\d -> { d | values = Dict.update paramId (\m -> Maybe.map (\_ -> newValue) m) d.values }) effects

        AddEffect ->
            effects ++ [ { type_ = Effect.Types.swap, values = Effect.defaultValues Effect.Types.swap } ]

        RemoveEffect ->
            List.take (List.length effects - 1) effects


effectFromId : String -> Maybe Effect.Type
effectFromId id =
    List.head <| List.filter (\e -> e.id == id) Effect.Types.all


viewField : Int -> Dict.Dict String Int -> Effect.Field -> Html Msg
viewField effectIdx values field =
    div [ class "tbm-field" ]
        [ label [ class "tbm-field__label" ] [ text field.name ]
        , input
            [ class "tbm-field__field"
            , type_ "number"
            , Html.Attributes.min (String.fromInt field.min)
            , Html.Attributes.max (String.fromInt field.max)
            , value <| String.fromInt <| Maybe.withDefault 0 <| Dict.get field.id values
            , onInput (\s -> SetParam effectIdx field.id <| Maybe.withDefault 0 (String.toInt s))
            ]
            []
        ]


viewEffectSelector : Int -> List Effect.Type -> Html Msg
viewEffectSelector effectIdx types =
    select [ class "tbm-effect__selector", onInput (SetType effectIdx << effectFromId) ] (List.map (\t -> option [ value t.id ] [ text t.name ]) types)


viewEffect : Int -> Effect.Instance -> Html Msg
viewEffect effectIdx effect =
    let
        validation =
            Effect.validateInstance effect
    in
    div
        [ class "tbm-effect"
        , classList
            [ ( "tbm-effect--error"
              , case validation of
                    Err _ ->
                        True

                    _ ->
                        False
              )
            ]
        ]
        [ h3 [ class "tbm-effect__header" ]
            [ text <| String.fromInt (effectIdx + 1) ++ ". "
            , viewEffectSelector effectIdx Effect.Types.all
            ]
        , case validation of
            Ok _ ->
                text ""

            Err [] ->
                p [ class "effect-error" ] [ text "An error occurred." ]

            Err (errorMsg :: _) ->
                p [ class "effect-error" ] [ text errorMsg ]
        , div [ class "tbm-effect__body" ]
            [ div [ class "tbm-effect__help" ]
                [ p [] [ text effect.type_.description ]
                ]
            , div [ class "tbm-effect__fields" ]
                [ if List.length effect.type_.params > 0 then
                    div [] (List.map (viewField effectIdx effect.values) effect.type_.params)

                  else
                    text "(No settings.)"
                ]
            ]
        ]


viewEffects : List Effect.Instance -> Html Msg
viewEffects effects =
    div [ class "container" ]
        (List.indexedMap viewEffect effects
            ++ [ div [ class "effect-controls" ]
                    [ a
                        [ class "button button-primary"
                        , on "click" <| D.succeed AddEffect
                        , disabled (List.length effects >= 5)
                        ]
                        [ FeatherIcons.toHtml [ height 16 ] FeatherIcons.plus ]
                    , a
                        [ class "button"
                        , on "click" <| D.succeed RemoveEffect
                        , disabled (List.length effects <= 1)
                        ]
                        [ FeatherIcons.toHtml [ height 16 ] FeatherIcons.minus ]
                    ]
               ]
        )
