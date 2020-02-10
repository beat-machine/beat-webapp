module Api exposing (ProcessingSettings, ProcessingPayload, SongSource(..), sendSong)

import Bytes exposing (Bytes)
import Dict
import Effect
import File exposing (File)
import Http exposing (filePart, jsonBody, multipartBody, post, stringPart)
import Json.Encode as Encode
import Validate
import Common.HttpExtras



-- MODELS


{-| A SongSource references a song that will be sent to the server.
-}
type SongSource
    = FromFile File
    | FromYoutubeUrl String


{-| ProcessingSettings specify extra settings that can be used to fine-tune
results from the API.
-}
type alias ProcessingSettings =
    { estimatedBpm : Int
    , tolerance : Int
    }


{-| A ProcessingPayload bundles all of the necessary information to send a
request to the server.
-}
type alias ProcessingPayload =
    { apiUrl : String
    , song : SongSource
    , settings : Maybe ProcessingSettings
    , effects : List (Validate.Valid Effect.Instance)
    }


-- ENCODING


encodeEffect : Effect.Instance -> Encode.Value
encodeEffect effect =
    let
        paramFields =
            effect.values
                -- Some effects have differences in the numbers we display to
                -- the user and the numbers that get sent to the server, so we
                -- need to apply those before sending them off.
                |> effect.type_.postValidation
                |> Dict.toList
                |> List.map (\( s, v ) -> ( s, Encode.int v ))
    in
    Encode.object <| ( "type", Encode.string effect.type_.id ) :: paramFields


effectsToJsonArray : List Effect.Instance -> Encode.Value
effectsToJsonArray effects =
    effects
        |> List.map encodeEffect
        |> Encode.list identity


encodeSettings : ProcessingSettings -> Encode.Value
encodeSettings settings =
    Encode.object
        [ ( "suggested_bpm", Encode.int settings.estimatedBpm )
        , ( "drift", Encode.int settings.tolerance )
        ]


-- API Calls


sendSongFromYouTube : String -> String -> Maybe ProcessingSettings -> List (Validate.Valid Effect.Instance) -> (Result String Bytes -> msg) -> Cmd msg
sendSongFromYouTube baseUrl youtubeUrl settings effects toMsg =
    let
        body =
            jsonBody <|
                Encode.object
                    [ ( "youtube_url", Encode.string youtubeUrl )
                    , ( "effects", effects |> List.map Validate.fromValid |> effectsToJsonArray )
                    , ( "settings", settings |> Maybe.map encodeSettings |> Maybe.withDefault (Encode.object []) )
                    ]
    in
    post
        { url = baseUrl ++ "/yt"
        , body = body
        , expect = Common.HttpExtras.expectRawBytes toMsg
        }


sendSongFromFile : String -> File -> Maybe ProcessingSettings -> List (Validate.Valid Effect.Instance) -> (Result String Bytes -> msg) -> Cmd msg
sendSongFromFile baseUrl file settings effects toMsg =
    let
        effectsObject =
            Encode.object
                [ ( "effects", effects |> List.map Validate.fromValid |> effectsToJsonArray )
                , ( "settings", settings |> Maybe.map encodeSettings |> Maybe.withDefault (Encode.object []) )
                ]

        body =
            multipartBody
                [ filePart "song" file
                , stringPart "effects" <| Encode.encode 0 effectsObject
                ]
    in
    post
        { url = baseUrl
        , body = body
        , expect = Common.HttpExtras.expectRawBytes toMsg
        }


{-|
Sends a song, effects, and settings to the API for processing.
-}
sendSong : ProcessingPayload -> (Result String Bytes -> msg) -> Cmd msg
sendSong payload toMsg =
    case payload.song of
        FromFile file ->
            sendSongFromFile payload.apiUrl file payload.settings payload.effects toMsg

        FromYoutubeUrl url ->
            sendSongFromYouTube payload.apiUrl url payload.settings payload.effects toMsg
