port module Main exposing (Model, Msg, init, subscriptions, update, updatePlayerSong, view)

import Api
import Base64
import Browser
import Bytes exposing (Bytes)
import Common.Content
import Effect
import Effect.Types
import Effect.View
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D
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
    , version : String
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
    { baseUrl : String
    , version : String
    , song : Maybe Api.SongSource
    , settings : Maybe Api.ProcessingSettings
    , inputMode : InputMode
    , effects : List Effect.Instance
    , processing : ProcessingState
    , tagline : String
    , filename : String
    }



-- UPDATE


type Msg
    = ChangeInputMode InputMode
    | SetSongUrl String
    | SetSongFile File
    | SendSong
    | GotSong (Result String Bytes)
    | EffectMsg Effect.View.Msg
    | ToggleCustomSettings
    | UpdateBpmEstimate Int
    | UpdateTolerance Int
    | NoOp
    | ChangeTagline String
    | RandomizeTagline


canSubmit : List Effect.Instance -> Bool
canSubmit effects =
    case Effect.validateAll effects of
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
            ( { model | song = Just <| Api.FromYoutubeUrl u, filename = "" }, Cmd.none )

        SetSongFile f ->
            ( { model | song = Just <| Api.FromFile f, filename = File.name f }, Cmd.none )

        SendSong ->
            case Effect.validateAll model.effects of
                Ok validEffects ->
                    case model.song of
                        Nothing ->
                            ( model, Cmd.none )

                        Just s ->
                            ( { model | processing = InProgress }
                            , Cmd.batch
                                [ clearPlayerSong ()
                                , Api.sendSong
                                    { apiUrl = model.baseUrl
                                    , song = s
                                    , settings = model.settings
                                    , effects = validEffects
                                    }
                                    GotSong
                                ]
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
            ( { model | effects = Effect.View.update m model.effects }, Cmd.none )

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
                    ( { model | settings = Just { s | estimatedBpm = i } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        UpdateTolerance i ->
            case model.settings of
                Just s ->
                    ( { model | settings = Just { s | tolerance = i } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


viewInfo : Model -> Html Msg
viewInfo model =
    section []
        [ h1 [ class "tbm-logo" ]
            [ p [ class "tbm-logo__word" ] [ text "The" ]
            , p [ class "tbm-logo__word" ] [ text "Beat" ]
            , p [ class "tbm-logo__word" ] [ text "Machine" ]
            ]
        , h3 [ class "tbm-tagline", onClick RandomizeTagline ] [ text model.tagline ]
        , p [] [ text "Make \"every other beat is missing\" remixes right in your browser -- and many other kinds of beat edits, too. Choose a song, stack some effects, and hear the results." ]
        ]


viewSongSelector : Model -> Html Msg
viewSongSelector model =
    section [ class "tbm-step" ]
        [ h2 [ class "tbm-step__header" ] [ text "Song" ]
        , p [] [ text "Choose and configure a song. Shorter songs process faster!" ]
        , div [ class "tbm-song-select" ]
            [ div [ class "tbm-song-select__source" ]
                [ h4 [ class "tbm-song-select__heading" ] [ text "Source" ]
                , label [ for "input-mode-audio" ]
                    [ input
                        [ onClick (ChangeInputMode File)
                        , type_ "radio"
                        , name "input-mode"
                        , id "input-mode-audio"
                        , checked (model.inputMode == File)
                        ]
                        []
                    , span [ ] [ text "Audio file" ]
                    ]
                , label [ for "input-mode-video" ]
                    [ input
                        [ onClick (ChangeInputMode Url)
                        , type_ "radio"
                        , name "input-mode"
                        , id "input-mode-video"
                        , checked (model.inputMode == Url)
                        ]
                        []
                    , span [ ] [ text "YouTube video" ]
                    ]
                ]
            , div [ class "tbm-song-select__input" ]
                [ case model.inputMode of
                    File ->
                        div []
                            [ h4 [ class "tbm-song-select__heading" ] [ text "Select file" ]
                            , input
                                [ type_ "file"
                                , multiple False
                                , accept "audio/mpeg, audio/x-wav, .mp3, .wav"
                                , on "change" (D.map SetSongFile filesDecoder)
                                ]
                                []
                            ]

                    Url ->
                        div []
                            [ h4 [ class "tbm-song-select__heading" ] [ text "Paste video URL" ]
                            , input
                                [ type_ "url"
                                , onInput SetSongUrl
                                ]
                                []
                            , p [] [ text "Some videos can't be downloaded. If you run into issues, try using an MP3." ]
                            ]
                ]
            ]
        , p [] [ text "If the result isn't as expected, you can fine-tune the tempo here. In most cases this isn't necessary." ]
        , div [ class "tbm-song-settings" ]
            [ div [ class "tbm-song-settings__toggles" ]
                [ label [ for "use-bpm" ]
                    [ input
                        [ type_ "checkbox"
                        , name "use-bpm"
                        , onClick ToggleCustomSettings
                        , checked (model.settings /= Nothing)
                        ]
                        []
                    , text "Set tempo manually"
                    ]
                ]
            , div [ class "tbm-song-settings__fields" ]
                [ div [ class "tbm-field" ]
                    [ label [ class "tbm-field__label" ] [ text "BPM" ]
                    , input
                        [ class "tbm-field__field"
                        , type_ "number"
                        , value
                            (case model.settings of
                                Just settings ->
                                    String.fromInt settings.estimatedBpm

                                Nothing ->
                                    ""
                            )
                        , onInput (String.toInt >> Maybe.withDefault 10 >> UpdateBpmEstimate)
                        , Html.Attributes.min "10"
                        , Html.Attributes.max "500"
                        , disabled (model.settings == Nothing)
                        ]
                        []
                    ]
                , div [ class "tbm-field" ]
                    [ label [ class "tbm-field__label" ] [ text "Tolerance" ]
                    , input
                        [ class "tbm-field__field"
                        , type_ "number"
                        , value
                            (case model.settings of
                                Just settings ->
                                    String.fromInt settings.tolerance

                                Nothing ->
                                    ""
                            )
                        , onInput (String.toInt >> Maybe.withDefault 3 >> UpdateTolerance)
                        , Html.Attributes.min "3"
                        , Html.Attributes.max "500"
                        , disabled (model.settings == Nothing)
                        ]
                        []
                    ]
                ]
            ]
        ]


loader : Html Msg
loader =
    div []
        [ p [ class "status" ] [ text "Working on it..." ]
        , div [ class "loader" ]
            [ div [ id "r1" ] []
            , div [ id "r2" ] []
            , div [ id "r3" ] []
            , div [ id "r4" ] []
            ]
        ]


viewResult : Model -> Html Msg
viewResult model =
    section [ class "tbm-step" ]
        [ h2 [ class "tbm-step__header" ] [ text "Result" ]
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
                loader

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
                , download model.filename
                , href "#"
                ]
                [ text "use this link" ]
            , text " to download the result."
            ]
        ]


view : Model -> Html Msg
view model =
    main_
        []
        [ viewInfo model
        , viewSongSelector model
        , section [ class "tbm-step" ]
            [ h2 [ class "tbm-step__header" ] [ text "Effects" ]
            , p []
                [ text "Add some effects to your song. Effects are applied in order, from top to bottom."
                ]
            , Html.map EffectMsg (Effect.View.viewEffects model.effects)
            ]
        , viewResult model

        -- , Common.Content.standardFooterInfo model.version "https://github.com/beat-machine" |> Common.Content.viewFooter
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
            [ { type_ = Effect.Types.swap, values = Effect.defaultValues Effect.Types.swap }
            ]
      , processing = NotStarted
      , tagline = ""
      , baseUrl = flags.baseUrl
      , version = flags.version
      , filename = ""
      }
    , selectNewTagline
    )



-- PORTS


{-| Clears the current song in the audio player.
-}
port clearPlayerSong : () -> Cmd msg


{-| Updates the current song in the audio player with a base64 audio stream.
-}
port updatePlayerSong : String -> Cmd msg
