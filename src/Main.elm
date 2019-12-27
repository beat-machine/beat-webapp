port module Main exposing (Model, Msg, init, subscriptions, update, updatePlayerSong, view)

import Api
import Base64
import Browser
import Bytes exposing (Bytes)
import EffectView
import Effects
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as D
import Patrons


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type InputSong
    = FromFile File
    | FromUrl String
    | None


type InputMode
    = File
    | Url


type CustomSettings
    = Disabled
    | EstimatedBpm Int Int


type ProcessingState
    = Succeeded
    | Failed String
    | InProgress
    | NotStarted


type alias Model =
    { song : InputSong
    , settings : CustomSettings
    , inputMode : InputMode
    , effects : EffectView.EffectCollection
    , processing : ProcessingState
    }



-- UPDATE


type Msg
    = ChangeInputMode InputMode
    | SetSongFile File
    | SendSong
    | GotSong (Result Http.Error Bytes)
    | EffectMsg EffectView.Msg
    | ToggleCustomSettings
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeInputMode m ->
            ( { model | inputMode = m }, Cmd.none )

        SetSongFile f ->
            ( { model | song = FromFile f }, Cmd.none )

        SendSong ->
            case model.song of
                None ->
                    ( model, Cmd.none )

                FromFile f ->
                    ( { model | processing = InProgress }, Api.sendFile f (Api.effectsToJsonString model.effects) GotSong )

                FromUrl _ ->
                    ( model, Cmd.none )

        ToggleCustomSettings ->
            ( { model
                | settings =
                    if model.settings == Disabled then
                        EstimatedBpm 120 10

                    else
                        Disabled
              }
            , Cmd.none
            )

        EffectMsg m ->
            ( { model | effects = EffectView.update m model.effects }, Cmd.none )

        GotSong result ->
            case result of
                Err a ->
                    ( { model | processing = Failed (Debug.toString a) }, Cmd.none )

                Ok s ->
                    case Base64.fromBytes s of
                        Just d ->
                            ( { model | processing = Succeeded }, updatePlayerSong d )

                        Nothing ->
                            ( { model | processing = Failed "Couldn't decode song" }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "container"
        , class "app"
        ]
        [ section []
            [ h1 [ class "one-word-per-line" ] [ text "The Beat Machine" ]
            , h3 [ class "tagline" ] [ text "funny tagline" ]
            , p [] [ text "Ever wondered what your favorite song sounds like with every other beat missing? No? Well, either way, now you can find out!" ]
            ]
        , section []
            [ h3 [] [ text "Song" ]
            , p [] [ text "Choose and configure a song. Shorter songs process faster!" ]
            , div [ class "row" ]
                [ div [ class "four", class "columns" ]
                    [ label [] [ text "Source" ]
                    , label []
                        [ input
                            [ onClick (ChangeInputMode File)
                            , type_ "radio"
                            , name "input-mode"
                            , checked (model.inputMode == File)
                            ]
                            []
                        , span [ class "label-body" ] [ text "MP3 File" ]
                        ]
                    , label []
                        [ input
                            [ onClick (ChangeInputMode Url)
                            , type_ "radio"
                            , name "input-mode"
                            , checked (model.inputMode == Url)
                            ]
                            []
                        , span [ class "label-body" ] [ text "YouTube Video" ]
                        ]
                    ]
                , div [ class "eight", class "columns" ]
                    [ case model.inputMode of
                        File ->
                            div []
                                [ label [] [ text "Select file" ]
                                , input
                                    [ type_ "file"
                                    , multiple False
                                    , accept "audio/mpeg, .mp3"
                                    , on "change" (D.map SetSongFile filesDecoder)
                                    ]
                                    []
                                ]

                        Url ->
                            div []
                                [ label [] [ text "Paste YouTube video URL" ]
                                , input [ type_ "url", class "u-full-width" ] []
                                ]
                    ]
                ]
            ]
        , section []
            [ h5 [] [ text "Settings" ]
            , p [] [ text "The following settings are optional, but let you fine-tune the result if it's not what you expected." ]
            , div [ class "row" ]
                [ div [ class "four", class "columns" ]
                    [ label []
                        [ input
                            [ type_ "checkbox"
                            , name "use-bpm"
                            , onClick ToggleCustomSettings
                            , checked (model.settings /= Disabled)
                            ]
                            []
                        , span [ class "label-body" ] [ text "Set tempo manually" ]
                        ]
                    ]
                , div [ class "four", class "columns" ]
                    [ label [] [ text "Estimated BPM" ]
                    , input [ type_ "number", value "120", class "u-full-width", disabled (model.settings == Disabled) ] []
                    ]
                , div [ class "four", class "columns" ]
                    [ label [] [ text "Max BPM Drift" ]
                    , input [ type_ "number", value "10", class "u-full-width", disabled (model.settings == Disabled) ] []
                    ]
                ]
            ]
        , section []
            [ h3 [] [ text "Effects" ]
            , p [] [ text "Add up to 5 effects to rearrange your song." ]
            , Html.map EffectMsg (EffectView.viewAllEffects model.effects)
            ]
        , section []
            [ h3 [] [ text "Result" ]
            , p [] [ text "Press submit to render the result!" ]
            , input
                [ type_ "button"
                , disabled (model.song == None || model.processing == InProgress || List.length model.effects <= 0)
                , onClick SendSong
                , value "Render!"
                , class "button-primary"
                ]
                []
            , case model.processing of
                InProgress ->
                    p [] [ text "Processing..." ]

                Failed errorMsg ->
                    p [] [ text ("An error occurred (" ++ errorMsg ++ "). ") ]

                _ ->
                    text ""
            , audio
                [ id "player"
                , controls True
                , classList [ ( "hidden", model.processing /= Succeeded ) ]
                ]
                []
            , a
                [ id "download"
                , download ""
                , classList [ ( "hidden", model.processing /= Succeeded ) ]
                ]
                [ text "Download Result" ]
            ]
        , section []
            [ h3 [] [ text "Support" ]
            , p [] [ text "Continued development of The Beat Machine is made possible by supporters on Patreon!" ]
            , div [ class "patrons" ] (List.map (\p -> Html.map (\_ -> NoOp) (Patrons.viewPatron p)) Patrons.all)
            , p [] [ text "If you'd like to have your name and links on this page, consider making a pledge." ]
            ]
        ]


filesDecoder : D.Decoder File
filesDecoder =
    D.at [ "target", "files" ] (D.index 0 File.decoder)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


init : () -> ( Model, Cmd Msg )
init _ =
    ( { song = None
      , inputMode = File
      , settings = Disabled
      , effects =
            [ { type_ = Effects.swap, values = Effects.defaultValues Effects.swap }
            ]
      , processing = NotStarted
      }
    , Cmd.none
    )



-- PORTS


port updatePlayerSong : String -> Cmd msg
