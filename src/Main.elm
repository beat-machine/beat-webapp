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
import Json.Decode as D
import Patrons
import Random
import Taglines


taglineGenerator : Random.Generator Int
taglineGenerator =
    Random.int 0 <| List.length Taglines.all


selectNewTagline : Cmd Msg
selectNewTagline =
    Random.generate (\i -> ChangeTagline <| Maybe.withDefault "???" <| (Taglines.all |> List.drop (i - 1) |> List.head)) taglineGenerator


type alias Flags =
    { baseUrl : String
    }


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type InputMode
    = File
    | Url


type ProcessingState
    = Succeeded
    | Failed String
    | InProgress
    | NotStarted


type alias Model =
    { song : Maybe Api.SongSource
    , settings : Maybe Api.ProcessingSettings
    , inputMode : InputMode
    , effects : EffectView.EffectCollection
    , processing : ProcessingState
    , tagline : String
    , baseUrl : String
    }



-- UPDATE


type Msg
    = ChangeInputMode InputMode
    | SetSongUrl String
    | SetSongFile File
    | SendSong
    | GotSong (Result String Bytes)
    | EffectMsg EffectView.Msg
    | ToggleCustomSettings
    | UpdateBpmEstimate Int
    | UpdateTolerance Int
    | NoOp
    | ChangeTagline String
    | RandomizeTagline


canSubmit : List Effects.EffectInstance -> Bool
canSubmit effects =
    case Effects.validateAll effects of
        Ok _ ->
            True

        _ ->
            False


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RandomizeTagline ->
            ( model, selectNewTagline )

        ChangeTagline s ->
            ( { model | tagline = s }, Cmd.none )

        ChangeInputMode m ->
            ( { model | inputMode = m }, Cmd.none )

        SetSongUrl u ->
            ( { model | song = Just <| Api.FromYoutubeUrl u }, Cmd.none )

        SetSongFile f ->
            ( { model | song = Just <| Api.FromFile f }, Cmd.none )

        SendSong ->
            case Effects.validateAll model.effects of
                Ok validEffects ->
                    case model.song of
                        Nothing ->
                            ( model, Cmd.none )

                        Just s ->
                            ( { model | processing = InProgress }
                            , Cmd.batch [ clearPlayerSong (), Api.sendSong model.baseUrl s model.settings validEffects GotSong ]
                            )

                Err _ ->
                    ( model, Cmd.none )

        ToggleCustomSettings ->
            ( { model
                | settings =
                    case model.settings of
                        Just _ ->
                            Nothing

                        Nothing ->
                            Just { estimatedBpm = 120, tolerance = 10 }
              }
            , Cmd.none
            )

        EffectMsg m ->
            ( { model | effects = EffectView.update m model.effects }, Cmd.none )

        GotSong result ->
            case result of
                Err s ->
                    ( { model | processing = Failed s }, Cmd.none )

                Ok s ->
                    case Base64.fromBytes s of
                        Just d ->
                            ( { model | processing = Succeeded }, updatePlayerSong d )

                        Nothing ->
                            ( { model | processing = Failed "Couldn't decode song" }, Cmd.none )

        UpdateBpmEstimate i ->
            case model.settings of
                Just s ->
                    ( { model | settings = Just { s | estimatedBpm = clamp 10 300 i } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        UpdateTolerance i ->
            case model.settings of
                Just s ->
                    ( { model | settings = Just { s | tolerance = clamp 3 300 i } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

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
            , h3 [ class "tagline", onClick RandomizeTagline ] [ text model.tagline ]
            , p [] [ text "Ever wondered what your favorite song sounds like with every other beat missing? No? Well, either way, now you can find out! The Beat Machine is a webapp for making beat edits to songs." ]
            ]
        , section [ class "frame" ]
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
                                , input
                                    [ type_ "url"
                                    , class "u-full-width"
                                    , onInput SetSongUrl
                                    ]
                                    []
                                , p [] [ text "Not all videos can be downloaded. If you run into issues, try using an MP3 instead." ]
                                ]
                    ]
                ]
            , br [] []
            , p [] [ text "The following settings are optional, but let you fine-tune the result if it's not what you expected. When using live performances or songs with tempo changes, be sure to set a high enough tolerance." ]
            , div [ class "row" ]
                [ div [ class "four", class "columns" ]
                    [ label []
                        [ input
                            [ type_ "checkbox"
                            , name "use-bpm"
                            , onClick ToggleCustomSettings
                            , checked (model.settings /= Nothing)
                            ]
                            []
                        , span [ class "label-body" ] [ text "Set tempo manually" ]
                        ]
                    ]
                , div [ class "four", class "columns" ]
                    [ label [] [ text "Estimated BPM" ]
                    , input
                        [ type_ "number"
                        , value
                            (case model.settings of
                                Just settings ->
                                    String.fromInt settings.estimatedBpm

                                Nothing ->
                                    ""
                            )
                        , onInput (String.toInt >> Maybe.withDefault 10 >> UpdateBpmEstimate)
                        , Html.Attributes.min "10"
                        , Html.Attributes.max "300"
                        , class "u-full-width"
                        , disabled (model.settings == Nothing)
                        ]
                        []
                    ]
                , div [ class "four", class "columns" ]
                    [ label [] [ text "Tolerance" ]
                    , input
                        [ type_ "number"
                        , value
                            (case model.settings of
                                Just settings ->
                                    String.fromInt settings.tolerance

                                Nothing ->
                                    ""
                            )
                        , onInput (String.toInt >> Maybe.withDefault 3 >> UpdateTolerance)
                        , Html.Attributes.min "3"
                        , Html.Attributes.max "300"
                        , class "u-full-width"
                        , disabled (model.settings == Nothing)
                        ]
                        []
                    ]
                ]
            ]
        , section [ class "frame" ]
            [ h3 [] [ text "Effects" ]
            , p [] [ text "Add up to 5 sequential effects to rearrange your song." ]
            , Html.map EffectMsg (EffectView.viewAllEffects model.effects)
            ]
        , section []
            [ h3 [] [ text "Support" ]
            , p [] [ text "Continued development of The Beat Machine is made possible by supporters on Patreon." ]
            , div [ class "patrons" ] (List.map (\p -> Html.map (\_ -> NoOp) (Patrons.viewPatron p)) Patrons.all)
            , p []
                [ text "If you'd like to keep the site online and promote yourself on this page, "
                , a [ href "https://www.patreon.com/branchpanic" ] [ text "consider making a pledge" ]
                , text "!"
                ]
            ]
        , section [ class "frame" ]
            [ h3 [] [ text "Result" ]
            , p [] [ text "Press the button to render the result! This will take a moment." ]
            , div [ class "render-button-container" ]
                [ button
                    [ disabled (model.song == Nothing || model.processing == InProgress || List.length model.effects <= 0 || not (canSubmit model.effects))
                    , onClick SendSong
                    , class "button-primary"
                    , class "render-button"
                    ]
                    [ text "Render!" ]
                ]
            , case model.processing of
                InProgress ->
                    div []
                        [ p [ class "status" ] [ text "Working on it..." ]
                        , div [ class "loader" ]
                            [ div [ id "r1" ] []
                            , div [ id "r2" ] []
                            , div [ id "r3" ] []
                            , div [ id "r4" ] []
                            ]
                        ]

                Failed errorMsg ->
                    p [ class "status", class "error" ] [ text errorMsg ]

                _ ->
                    text ""
            , audio
                [ id "player"
                , controls True
                , classList [ ( "hidden", model.processing /= Succeeded ) ]
                ]
                []
            , p [ classList [ ( "hidden", model.processing /= Succeeded ) ], class "audio-hint" ]
                [ text "Right-click on the player above or "
                , a
                    [ id "download"
                    , download ""
                    , href "test"
                    ]
                    [ text "use this link" ]
                , text " to download the result."
                ]
            ]
        , footer []
            [ p []
                [ text "Version 20.01.0. Created by "
                , a [ href "https://twitter.com/branchpanic" ] [ text "@branchpanic" ]
                , text ". Check out the source "
                , a [ href "https://github.com/beat-machine" ] [ text "on GitHub" ]
                , text "."
                ]
            ]
        ]


filesDecoder : D.Decoder File
filesDecoder =
    D.at [ "target", "files" ] (D.index 0 File.decoder)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { song = Nothing
      , inputMode = File
      , settings = Nothing
      , effects =
            [ { type_ = Effects.swap, values = Effects.defaultValues Effects.swap }
            ]
      , processing = NotStarted
      , tagline = ""
      , baseUrl = flags.baseUrl
      }
    , selectNewTagline
    )



-- PORTS


port clearPlayerSong : () -> Cmd msg


port updatePlayerSong : String -> Cmd msg
