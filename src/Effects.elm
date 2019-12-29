module Effects exposing (EffectInstance, EffectType, ParamInfo, all, defaultValues, effectValidator, validateAll, randomize, swap)

import Dict exposing (Dict)
import Validate exposing (Validator)


type alias ParamInfo =
    { id : String
    , name : String
    , hint : Maybe String
    , min : Int
    , max : Int
    , default : Int
    }


type alias EffectType =
    { name : String
    , description : String
    , id : String
    , params : List ParamInfo
    , extraValidation : List (Validator String (Dict String Int))
    , postValidation : Dict String Int -> Dict String Int
    }


type alias EffectInstance =
    { type_ : EffectType
    , values : Dict.Dict String Int
    }


effectValidator : EffectType -> Validator String EffectInstance
effectValidator e =
    Validate.all
        -- Check that all fields are present.
        (List.map (\p -> Validate.ifNothing (\d -> Dict.get p d.values) "Missing field") (List.map .id e.params)
            -- Check that all values are in the appropriate range.
            ++ List.map
                (\p ->
                    Validate.ifTrue
                        (\d ->
                            case Dict.get p.id d.values of
                                Just i ->
                                    i < p.min

                                Nothing ->
                                    True
                        )
                        ("The value for setting \"" ++ p.name ++ "\" is too low. Set it to at least " ++ String.fromInt p.min ++ ".")
                )
                e.params
            ++ List.map
                (\p ->
                    Validate.ifTrue
                        (\d ->
                            case Dict.get p.id d.values of
                                Just i ->
                                    i > p.max

                                Nothing ->
                                    True
                        )
                        ("The value for setting \"" ++ p.name ++ "\" is too high. Set it to at most " ++ String.fromInt p.max ++ ".")
                )
                e.params
            -- Apply any extra validation.
            ++ [ Validate.fromErrors
                    (\a ->
                        case Validate.validate (Validate.all e.extraValidation) a.values of
                            Ok _ ->
                                []

                            Err errs ->
                                errs
                    )
               ]
        )


validateAll : List EffectInstance -> Result (List (List String)) (List (Validate.Valid EffectInstance))
validateAll effects =
    let
        result =
            List.map (\e -> Validate.validate (effectValidator e.type_) e) effects

        oks =
            List.filterMap
                (\r ->
                    case r of
                        Ok v ->
                            Just v

                        _ ->
                            Nothing
                )
                result

        errs =
            List.filterMap
                (\r ->
                    case r of
                        Err e ->
                            Just e

                        _ ->
                            Nothing
                )
                result
    in
    if List.length oks == List.length effects then
        Ok oks

    else
        Err errs


defaultValues : EffectType -> Dict String Int
defaultValues e =
    Dict.fromList <| List.map (\p -> ( p.id, p.default )) e.params


all : List EffectType
all =
    [ swap, randomize, remove, cut, repeat, silence, reverse ]


swap : EffectType
swap =
    { id = "swap"
    , name = "Swap"
    , description = "Swaps two beats over the entire song."
    , params =
        [ { id = "x_period", name = "Every", hint = Nothing, min = 1, default = 2, max = 1000 }
        , { id = "y_period", name = "With", hint = Nothing, min = 1, default = 4, max = 1000 }
        ]
    , extraValidation = [ Validate.ifTrue (\m -> Dict.get "x_period" m == Dict.get "y_period" m) "Can't swap a beat with itself! Try changing one of the values below." ]
    , postValidation = identity
    }


randomize : EffectType
randomize =
    { id = "randomize"
    , name = "Randomize"
    , description = "Totally randomize all beats."
    , params = []
    , extraValidation = []
    , postValidation = identity
    }


remove : EffectType
remove =
    { id = "remove"
    , name = "Remove"
    , description = "Remove beats entirely."
    , params =
        [ { id = "period", name = "Every", hint = Nothing, min = 2, default = 2, max = 1000 }
        ]
    , extraValidation = []
    , postValidation = identity
    }


cut : EffectType
cut =
    { id = "cut"
    , name = "Cut"
    , description = "Cut beats into pieces and keep one of them."
    , params =
        [ { id = "period", name = "Every", hint = Nothing, min = 1, default = 2, max = 1000 }
        , { id = "denominator", name = "Pieces", hint = Nothing, min = 2, default = 2, max = 1000 }
        , { id = "take_index", name = "Piece to Keep", hint = Nothing, min = 1, default = 1, max = 1000 }
        ]
    , extraValidation = [ Validate.ifTrue (\m -> (Maybe.withDefault 0 <| Dict.get "take_index" m) > (Maybe.withDefault 0 <| Dict.get "denominator" m)) "Each beat isn't being cut into enough pieces to take that one. Try increasing the number of pieces." ]
    , postValidation = Dict.update "take_index" (Maybe.map (\i -> i - 1))
    }


repeat : EffectType
repeat =
    { id = "repeat"
    , name = "Repeat"
    , description = "Repeat beats a certain number of times."
    , params =
        [ { id = "period", name = "Every", hint = Nothing, min = 1, default = 2, max = 1000 }
        , { id = "times", name = "Times", hint = Nothing, min = 1, default = 2, max = 1000 }
        ]
    , extraValidation = []
    , postValidation = identity
    }


silence : EffectType
silence =
    { id = "silence"
    , name = "Silence"
    , description = "Silences beats, but retains their length."
    , params =
        [ { id = "period", name = "Every", hint = Nothing, min = 2, default = 2, max = 1000 }
        ]
    , extraValidation = []
    , postValidation = identity
    }


reverse : EffectType
reverse =
    { id = "reverse"
    , name = "Reverse"
    , description = "Reverses beats."
    , params =
        [ { id = "period", name = "Every", hint = Nothing, min = 1, default = 2, max = 1000 }
        ]
    , extraValidation = []
    , postValidation = identity
    }
