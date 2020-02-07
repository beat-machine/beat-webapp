module Patrons exposing (Patron, all, viewPatron)

import FeatherIcons exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)


type alias Patron =
    { name : String
    , tier : Int
    , links : List ( FeatherIcons.Icon, String )
    }


all : List Patron
all =
    [ { name = "Thomas L"
      , tier = 1
      , links =
            [ ( youtube, "https://www.youtube.com/channel/UCThULshLB0qiEoL73KxeNbQ" ) ]
      }
    ]


viewPatron : Patron -> Html ()
viewPatron patron =
    div [ class "patron", class <| "tier-" ++ String.fromInt patron.tier ]
        [ h5 [] (text patron.name :: List.map (\( icon, url ) -> a [ href url ] [ FeatherIcons.toHtml [ height 18 ] icon ]) patron.links)
        ]
