module Common.Content exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type alias FooterInfo =
    { version : String
    , twitterUrl : String
    , twitterHandle : String
    , githubUrl : String
    }


standardFooterInfo : String -> String -> FooterInfo
standardFooterInfo version githubUrl =
    { version = version
    , twitterUrl = "https://twitter.com/branchpanic"
    , twitterHandle = "@branchpanic"
    , githubUrl = githubUrl
    }


viewFooter : FooterInfo -> Html msg
viewFooter info =
    footer []
        [ p []
            [ text <| "Version " ++ info.version ++ ". Created by "
            , a [ href info.twitterUrl ] [ text info.twitterHandle ]
            , text ". Check out the source "
            , a [ href info.githubUrl ] [ text "on GitHub" ]
            , text "."
            ]
        ]


viewNavbar : Html msg
viewNavbar =
    nav []
        [ a [ href "https://branchpanic.me/" ] [ text "Home" ]
        , a [ href "https://branchpanic.itch.io/vdcrpt" ] [ text "vdcrpt" ]
        , a [ href "https://beatmachine.branchpanic.me/" ] [ text "The Beat Machine" ]
        , a [ href "https://gifsync.branchpanic.me/" ] [ text "Gifsync" ]
        ]
