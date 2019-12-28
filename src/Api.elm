module Api exposing (SongSource (..), sendSong)

import Bytes exposing (Bytes)
import Dict
import EffectView
import File exposing (File)
import Http exposing (filePart, multipartBody, post, stringPart, jsonBody)
import Json.Encode as Encode


type SongSource
    = FromFile File
    | FromYoutubeUrl String

baseUrl : String
baseUrl =
    "http://localhost:8000"


effectsToJsonArray : List EffectView.EffectInstance -> Encode.Value
effectsToJsonArray effects =
    Encode.list Encode.object <|
        List.map
            (\e ->
                ( "type", Encode.string e.type_.id )
                    :: (List.map (\( s, v ) -> ( s, Encode.int v )) <| Dict.toList (e.type_.postValidation e.values))
            )
            effects


sendSong : SongSource -> List EffectView.EffectInstance -> (Result Http.Error Bytes -> msg) -> Cmd msg
sendSong song effects toMsg =
    let
        endpoint = case song of
            FromFile _ ->
                baseUrl
            FromYoutubeUrl _ ->
                baseUrl ++ "/yt"

        body = case song of
            FromFile f ->
                multipartBody
                    [ filePart "song" f
                    , stringPart "effects" (Encode.encode 0 <| effectsToJsonArray effects)
                    ]
        
            FromYoutubeUrl u ->
                jsonBody (Encode.object [ ( "youtube_url", Encode.string u ), ( "effects", effectsToJsonArray effects ), ( "settings", Encode.object [] )])
        
    in            
        post
            { url = endpoint
            , body = body
            , expect = expectSongBytes toMsg
            }


expectSongBytes : (Result Http.Error Bytes -> msg) -> Http.Expect msg
expectSongBytes toMsg =
    Http.expectBytesResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata _ ->
                    Err (Http.BadStatus metadata.statusCode)

                Http.GoodStatus_ _ body ->
                    Ok body
