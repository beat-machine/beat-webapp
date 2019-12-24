module Effects exposing (EffectType, ParamInfo, all, defaultValues, effectValidator, randomize, swap)

import Dict exposing (Dict)
import Validate exposing (Validator)


type alias ParamInfo =
    { name : String
    , hint : Maybe String
    , min : Int
    , max : Int
    , default : Int
    }


type alias EffectType =
    { name : String
    , description : String
    , id : String
    , params : Dict String ParamInfo
    , extraValidation : List (Validator String (Dict String Int))
    }


effectValidator : EffectType -> Validator String (Dict String Int)
effectValidator e =
    Validate.all (List.map (\k -> Validate.ifNothing (\m -> Dict.get k m) "Missing field") (Dict.keys e.params) ++ e.extraValidation)


defaultValues : EffectType -> Dict String Int
defaultValues e =
    Dict.map (\_ p -> p.default) e.params


all : List EffectType
all =
    [ swap, randomize ]


swap : EffectType
swap =
    { id = "swap"
    , name = "Swap"
    , description = "Swaps two beats over the entire song."
    , params =
        Dict.fromList
            [ ( "x_period", { name = "Every", hint = Nothing, min = 0, default = 2, max = 1000 } )
            , ( "y_period", { name = "With", hint = Nothing, min = 0, default = 4, max = 1000 } )
            ]
    , extraValidation = [ Validate.ifTrue (\m -> Dict.get "x_period" m == Dict.get "y_period" m) "Can't swap a beat with itself" ]
    }


randomize : EffectType
randomize =
    { id = "randomize"
    , name = "Randomize"
    , description = "Totally randomizes all beats."
    , params = Dict.empty
    , extraValidation = []
    }
