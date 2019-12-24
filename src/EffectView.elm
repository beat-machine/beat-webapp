module EffectView exposing (EffectCollection, EffectInstance, Msg, update, viewAllEffects)

import Dict
import Effects
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type alias EffectInstance =
    { type_ : Effects.EffectType
    , values : Dict.Dict String Int
    }


type alias EffectCollection =
    List EffectInstance


type Msg
    = SetType Int (Maybe Effects.EffectType)
    | SetParam Int String Int


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


effectFromId : String -> Maybe Effects.EffectType
effectFromId id =
    List.head <| List.filter (\e -> e.id == id) Effects.all


viewParam : Int -> Dict.Dict String Int -> ( String, Effects.ParamInfo ) -> Html Msg
viewParam effectIdx paramValues ( paramId, paramInfo ) =
    div [ class "param" ]
        [ label [] [ text paramInfo.name ]
        , input
            [ type_ "number"
            , Html.Attributes.min (String.fromInt paramInfo.min)
            , Html.Attributes.max (String.fromInt paramInfo.max)
            , value <| String.fromInt <| Maybe.withDefault 0 <| Dict.get paramId paramValues
            , onInput (\s -> SetParam effectIdx paramId <| Maybe.withDefault 0 (String.toInt s))
            ]
            []
        ]


viewEffectSelector : Int -> List Effects.EffectType -> Html Msg
viewEffectSelector effectIdx types =
    select [ onInput (SetType effectIdx << effectFromId) ] (List.map (\t -> option [ value t.id ] [ text t.name ]) types)


viewEffect : Int -> EffectInstance -> Html Msg
viewEffect effectIdx effect =
    div []
        ([ viewEffectSelector effectIdx Effects.all, p [] [ text effect.type_.description ] ]
            ++ List.map (viewParam effectIdx effect.values) (Dict.toList effect.type_.params)
        )


viewAllEffects : EffectCollection -> Html Msg
viewAllEffects effects =
    div [] (List.indexedMap viewEffect effects)
