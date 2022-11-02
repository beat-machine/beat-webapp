module Common.Content exposing (..)

import Common.Patreon
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


viewPatreonSection : msg -> String -> Html msg
viewPatreonSection noOpMsg siteName =
    section []
        [ h3 [] [ text "Patreon" ]
        , p [] [ text <| "Continued development of " ++ siteName ++ " and related projects is made possible by supporters on Patreon." ]
        , div [ class "patrons" ] <| (Common.Patreon.allPatrons |> List.map (\p -> Html.map (\_ -> noOpMsg) (Common.Patreon.viewPatron p)))
        , p []
            [ text "Help keep the site working, contribute to further speed improvements, and promote yourself on this page by "
            , a [ href "https://www.patreon.com/branchpanic" ] [ text "making a pledge!" ]
            ]
        ]


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
        [ a [ href "https://beatmachine.branchpanic.me/" ] [ text "The Beat Machine" ]
        , a [ href "https://gifsync.branchpanic.me/" ] [ text "Gifsync" ]
        , a [ href "https://branchpanic.itch.io/vdcrpt" ] [ text "vdcrpt" ]
        ]
