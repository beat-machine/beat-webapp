module EffectView exposing (EffectCollection, Msg, update, validateInstance, viewAllEffects)

import Dict
import Effects
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D
import Validate


type alias EffectCollection =
    List Effects.EffectInstance


type Msg
    = SetType Int (Maybe Effects.EffectType)
    | SetParam Int String Int
    | AddEffect
    | RemoveEffect


validateInstance : Effects.EffectInstance -> Result (List String) (Validate.Valid Effects.EffectInstance)
validateInstance effect =
    Validate.validate (Effects.effectValidator effect.type_) effect


mapAt : Int -> (a -> a) -> List a -> List a
mapAt idx f list =
    List.indexedMap
        (\i v ->
            if i == idx then
                f v

            else
                v
        )
        list


update : Msg -> EffectCollection -> EffectCollection
update msg effects =
    case msg of
        SetType idx maybeNewType ->
            case maybeNewType of
                Just newType ->
                    mapAt idx (\_ -> { type_ = newType, values = Effects.defaultValues newType }) effects

                Nothing ->
                    effects

        SetParam idx paramId newValue ->
            mapAt idx (\d -> { d | values = Dict.update paramId (\m -> Maybe.map (\_ -> newValue) m) d.values }) effects

        AddEffect ->
            effects ++ [ { type_ = Effects.swap, values = Effects.defaultValues Effects.swap } ]

        RemoveEffect ->
            List.take (List.length effects - 1) effects


effectFromId : String -> Maybe Effects.EffectType
effectFromId id =
    List.head <| List.filter (\e -> e.id == id) Effects.all


viewParam : Int -> Dict.Dict String Int -> Effects.ParamInfo -> Html Msg
viewParam effectIdx paramValues paramInfo =
    div [ class "param" ]
        [ label [] [ text paramInfo.name ]
        , input
            [ class "u-full-width"
            , type_ "number"
            , Html.Attributes.min (String.fromInt paramInfo.min)
            , Html.Attributes.max (String.fromInt paramInfo.max)
            , value <| String.fromInt <| Maybe.withDefault 0 <| Dict.get paramInfo.id paramValues
            , onInput (\s -> SetParam effectIdx paramInfo.id <| Maybe.withDefault 0 (String.toInt s))
            ]
            []
        ]


viewEffectSelector : Int -> List Effects.EffectType -> Html Msg
viewEffectSelector effectIdx types =
    select [ class "effect-type", class "u-full-width", onInput (SetType effectIdx << effectFromId) ] (List.map (\t -> option [ value t.id ] [ text t.name ]) types)


viewEffect : Int -> Effects.EffectInstance -> Html Msg
viewEffect effectIdx effect =
    let
        validation =
            validateInstance effect
    in
    section
        [ class "frame"
        , classList
            [ ( "error"
              , case validation of
                    Err _ ->
                        True

                    _ ->
                        False
              )
            ]
        ]
        [ h5 [] [ text <| String.fromInt (effectIdx + 1) ++ ". " ++ effect.type_.name ]
        , case validation of
            Ok _ ->
                text ""

            Err [] ->
                p [ class "effect-error" ] [ text "An error occurred." ]

            Err (errorMsg :: _) ->
                p [ class "effect-error" ] [ text errorMsg ]
        , div [ class "row" ]
            [ div [ class "five", class "columns" ]
                [ label [] [ text "Type" ]
                , viewEffectSelector effectIdx Effects.all
                , p [ class "effect-desc" ] [ text effect.type_.description ]
                ]
            , if List.length effect.type_.params > 0 then
                div [ class "seven", class "columns" ] (List.map (viewParam effectIdx effect.values) effect.type_.params)

              else
                text ""
            ]
        ]


viewAllEffects : EffectCollection -> Html Msg
viewAllEffects effects =
    div [ class "container" ]
        (List.indexedMap viewEffect effects
            ++ [ div [ class "effect-controls" ]
                    [ button [ class "button-primary", on "click" <| D.succeed AddEffect, disabled (List.length effects >= 5) ] [ text "+" ]
                    , button [ on "click" <| D.succeed RemoveEffect, disabled (List.length effects <= 1) ] [ text "-" ]
                    ]
               ]
        )
