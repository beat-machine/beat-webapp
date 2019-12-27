module Api exposing (sendFile, effectsToJsonString)

import Bytes exposing (Bytes)
import Dict
import EffectView
import File exposing (File)
import Http exposing (filePart, multipartBody, post, stringPart)
import Json.Encode as Encode


baseUrl : String
baseUrl =
    "http://localhost:8000"


effectsToJsonString : List EffectView.EffectInstance -> String
effectsToJsonString effects =
    Encode.encode 0 <|
        Encode.list Encode.object <|
            List.map
                (\e ->
                    ( "type", Encode.string e.type_.id )
                        :: (List.map (\( s, v ) -> ( s, Encode.int v )) <| Dict.toList e.values)
                )
                effects


sendFile : File -> String -> (Result Http.Error Bytes -> msg) -> Cmd msg
sendFile song effects toMsg =
    post
        { url = baseUrl
        , body =
            multipartBody
                [ filePart "song" song
                , stringPart "effects" effects
                ]
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
