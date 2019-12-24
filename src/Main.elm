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


type alias Model =
    { song : InputSong
    , inputMode : InputMode
    , error : Maybe String
    , effects : EffectView.EffectCollection
    }



-- UPDATE


type Msg
    = ChangeInputMode InputMode
    | SetSongFile File
    | SendSong
    | GotSong (Result Http.Error Bytes)
    | ClearSong
    | EffectMsg EffectView.Msg


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
                    ( model, Api.sendFile f "[{\"type\": \"cut\", \"period\": 1}]" GotSong )

                FromUrl _ ->
                    ( model, Cmd.none )

        ClearSong ->
            ( { model | song = None, error = Nothing }, Cmd.none )

        EffectMsg m ->
            ( { model | effects = EffectView.update m model.effects }, Cmd.none )

        GotSong result ->
            case result of
                Err a ->
                    ( { model | error = Just (Debug.toString a) }, Cmd.none )

                Ok s ->
                    case Base64.fromBytes s of
                        Just d ->
                            ( model, updatePlayerSong d )

                        Nothing ->
                            ( { model | error = Just "Couldn't decode song" }, Cmd.none )



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
            ]
        , section [ class "frame" ]
            [ h3 [] [ text "Song" ]
            , div [ class "tabs" ]
                [ button
                    [ classList [ ( "active", model.inputMode == File ) ]
                    , onClick (ChangeInputMode File)
                    ]
                    [ text "Upload MP3" ]
                , span [] [ text "or" ]
                , button
                    [ classList [ ( "active", model.inputMode == Url ) ]
                    , onClick (ChangeInputMode Url)
                    ]
                    [ text "Paste YouTube Link" ]
                ]
            , case model.inputMode of
                File ->
                    input
                        [ type_ "file"
                        , multiple False
                        , accept "audio/mpeg, .mp3"
                        , on "change" (D.map SetSongFile filesDecoder)
                        ]
                        []

                Url ->
                    input [ type_ "url" ] []
            ]
        , section [ class "frame" ]
            [ h3 [] [ text "Effects" ]
            , Html.map EffectMsg (EffectView.viewAllEffects model.effects)
            ]
        , section []
            [ h3 [] [ text "Support" ]
            , p [] [ text "Continued development of The Beat Machine is made possible by supporters on Patreon." ]
            ]
        , section [ class "frame" ]
            [ h3 [] [ text "Result" ]
            , input
                [ type_ "button"
                , disabled (model.song == None)
                , onClick SendSong
                , value "Submit"
                ]
                []
            , audio
                [ id "player"
                , controls True
                ]
                []
            , a
                [ id "download"
                , download ""
                ]
                [ text "Download Result" ]
            , case model.error of
                Just e ->
                    p [] [ text e ]

                Nothing ->
                    text ""
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
      , error = Nothing
      , effects = [ { type_ = Effects.swap, values = Effects.defaultValues Effects.swap } ]
      }
    , Cmd.none
    )



-- PORTS


port updatePlayerSong : String -> Cmd msg
