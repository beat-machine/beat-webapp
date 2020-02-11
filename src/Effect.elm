module Effect exposing (Instance, Type, Field, defaultValues, instanceValidator, validateAll, validateInstance)

import Dict exposing (Dict)
import Validate exposing (Validator)


-- MODELS


{-| A Field is a ranged integer parameter for an effect. -}
type alias Field =
    { id : String
    , name : String
    , hint : Maybe String
    , min : Int
    , max : Int
    , default : Int
    }


{-| A Type is a class of effect, defined by a set of fields and optionally
custom validation and serialization logic.
-}
type alias Type =
    { name : String
    , description : String
    , id : String
    , params : List Field
    , extraValidation : List (Validator String (Dict String Int))
    , postValidation : Dict String Int -> Dict String Int
    }


{-| An Instance is a Type coupled with a Dict.Dict representing the values of
each Field. Instances should be used with caution, because they may or may not
be constructed correctly. To ensure a proper instance is passed, require a 
`Validate.Valid Instance`.
-}
type alias Instance =
    { type_ : Type
    , values : Dict.Dict String Int
    }


{-| Retrieves the default values for the given effect type. -}
defaultValues : Type -> Dict String Int
defaultValues i =
    i.params
    |> List.map (\p -> ( p.id, p.default ))
    |> Dict.fromList


-- VALIDATION


{-| A validator for checking if a field is within its defined range in an instance. -}
rangeValidator : Field -> Validator String Instance
rangeValidator f =
    Validate.ifTrue
        (\d ->
            case Dict.get f.id d.values of
                Just i ->
                    i < f.min || i > f.max

                Nothing ->
                    True
        )
        ("The value for setting \""
        ++ f.name
        ++ "\" is out of range. Put it in the range ["
        ++ String.fromInt f.min
        ++ ", "
        ++ String.fromInt f.max
        ++ "]."
        )


{-| A validator for checking if a field is present in an instance. -}
presenceValidator : Field -> Validator String Instance
presenceValidator f =
    Validate.ifNothing (\i -> Dict.get f.id i.values) ("Missing field " ++ f.id)


{-| A validator that applies any type-specific checks for an instance. -}
typeSpecificValidator : Type -> Validator String Instance
typeSpecificValidator t =
    Validate.fromErrors
        (\i ->
            case Validate.validate (Validate.all t.extraValidation) i.values of
                Ok _ ->
                    []

                Err errs ->
                    errs
        )


{-| A validator that runs all necessary checks on an instance and its fields. -}
instanceValidator : Type -> Validator String Instance
instanceValidator t =
    [typeSpecificValidator t]
    |> (++) (List.map presenceValidator t.params)
    |> (++) (List.map rangeValidator t.params)
    |> Validate.all


{-| Validates an instance, returning a list of human-friendly errors or a
`Validate.Valid Instance`.
-}
validateInstance : Instance -> Result (List String) (Validate.Valid Instance)
validateInstance i =
    Validate.validate (instanceValidator i.type_) i


validateAll : List Instance -> Result (List (List String)) (List (Validate.Valid Instance))
validateAll effects =
    let
        result =
            List.map (\e -> Validate.validate (instanceValidator e.type_) e) effects

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
