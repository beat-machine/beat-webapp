module Effect.Types exposing (..)

import Dict
import Effect
import Validate


all : List Effect.Type
all =
    [ swap, randomize, remove, cut, repeat, silence, reverse ]


standardOffsetField : Effect.Field
standardOffsetField =
    { id = "offset"
    , name = "Offset"
    , hint = Just "Number of beats to wait before applying this effect"
    , min = 0
    , default = 0
    , max = 1000
    }


swapPeriodValidator : Validate.Validator String (Dict.Dict String Int)
swapPeriodValidator = 
    Validate.ifTrue (\v -> Dict.get "x_period" v == Dict.get "y_period" v) "Can't swap a beat with itself! Change one of the values below."

swap : Effect.Type
swap =
    { id = "swap"
    , name = "Swap"
    , description = "Swaps two beats throughout the entire song."
    , params =
        [ { id = "x_period", name = "Every", hint = Nothing, min = 1, default = 2, max = 1000 }
        , { id = "y_period", name = "With", hint = Nothing, min = 1, default = 4, max = 1000 }
        , standardOffsetField
        ]
    , extraValidation = [ swapPeriodValidator ]
    , postValidation = identity
    }


randomize : Effect.Type
randomize =
    { id = "randomize"
    , name = "Randomize"
    , description = "Totally randomizes the order of all beats."
    , params = []
    , extraValidation = []
    , postValidation = identity
    }


remove : Effect.Type
remove =
    { id = "remove"
    , name = "Remove"
    , description = "Removes beats entirely."
    , params =
        [ { id = "period", name = "Every", hint = Nothing, min = 2, default = 2, max = 1000 }
        , standardOffsetField
        ]
    , extraValidation = []
    , postValidation = identity
    }


cutIndexValidator : Validate.Validator String (Dict.Dict String Int)
cutIndexValidator =
    Validate.ifTrue
        (\m -> (Maybe.withDefault 0 <| Dict.get "take_index" m) > (Maybe.withDefault 0 <| Dict.get "denominator" m))
        "Each beat isn't being cut into enough pieces to take that one. Try increasing the number of pieces."

cut : Effect.Type
cut =
    { id = "cut"
    , name = "Cut"
    , description = "Cuts beats into pieces and keeps one of them (i.e. pieces = 2, piece to keep = 2 takes the second half of each beat)."
    , params =
        [ { id = "period", name = "Every", hint = Nothing, min = 1, default = 2, max = 1000 }
        , standardOffsetField
        , { id = "denominator", name = "Pieces", hint = Nothing, min = 2, default = 2, max = 1000 }
        , { id = "take_index", name = "Piece to Keep", hint = Nothing, min = 1, default = 1, max = 1000 }
        ]
    , extraValidation = [cutIndexValidator]
    , postValidation = Dict.update "take_index" (Maybe.map (\i -> i - 1))
    }


repeat : Effect.Type
repeat =
    { id = "repeat"
    , name = "Repeat"
    , description = "Repeat beats a certain number of times."
    , params =
        [ { id = "period", name = "Every", hint = Nothing, min = 1, default = 2, max = 1000 }
        , standardOffsetField
        , { id = "times", name = "Times", hint = Nothing, min = 1, default = 2, max = 1000 }
        ]
    , extraValidation = []
    , postValidation = identity
    }


silence : Effect.Type
silence =
    { id = "silence"
    , name = "Silence"
    , description = "Silences beats, but retains their length."
    , params =
        [ { id = "period", name = "Every", hint = Nothing, min = 2, default = 2, max = 1000 }
        , standardOffsetField
        ]
    , extraValidation = []
    , postValidation = identity
    }


reverse : Effect.Type
reverse =
    { id = "reverse"
    , name = "Reverse"
    , description = "Reverses individual beats."
    , params =
        [ { id = "period", name = "Every", hint = Nothing, min = 1, default = 2, max = 1000 }
        , standardOffsetField
        ]
    , extraValidation = []
    , postValidation = identity
    }
