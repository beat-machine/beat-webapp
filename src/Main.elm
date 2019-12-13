module Main exposing (Model, Msg, init, subscriptions, update, view)

import Api
import Browser
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
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
    , result : Maybe String
    }



-- UPDATE


type Msg
    = SetSongFile File
    | SendSong
    | ApiMsg Api.Msg
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
                    ( model, Api.sendFile f "[]" |> Cmd.map ApiMsg )

        ClearSong ->
            ( { model | song = None }, Cmd.none )

        ApiMsg apiMsg -> 
            ( model, Cmd.none )
                

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
        , audio [ controls True ] []
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
      , result = Nothing
      }
    , Cmd.none
    )
