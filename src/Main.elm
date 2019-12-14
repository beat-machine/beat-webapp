port module Main exposing (Model, Msg, init, subscriptions, update, updatePlayerSong, view)

import Api
import Base64
import Browser
import Bytes exposing (Bytes)
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
    | None


type alias Model =
    { song : InputSong
    , error : Maybe String
    }


-- UPDATE


type Msg
    = SetSongFile File
    | SendSong
    | GotSong (Result Http.Error Bytes)
    | ClearSong


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetSongFile f ->
            ( { model | song = FromFile f }, Cmd.none )

        SendSong ->
            case model.song of
                None ->
                    ( model, Cmd.none )

                FromFile f ->
                    ( model, Api.sendFile f "[{\"type\": \"cut\", \"period\": 1}]" GotSong )

        ClearSong ->
            ( { model | song = None, error = Nothing }, Cmd.none )

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
    div []
        [ input
            [ type_ "file"
            , multiple False
            , accept "audio/mpeg, .mp3"
            , on "change" (D.map SetSongFile filesDecoder)
            ]
            []
        , input
            [ type_ "button"
            , onClick ClearSong
            , value "Reset"
            ]
            []
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
        , pre [] [ text (Debug.toString model) ]
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
      , error = Nothing
      }
    , Cmd.none
    )



-- PORTS


port updatePlayerSong : String -> Cmd msg
