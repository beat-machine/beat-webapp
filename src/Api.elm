module Api exposing (sendFile)

import Bytes exposing (Bytes)
import File exposing (File)
import Http exposing (filePart, multipartBody, post, stringPart)


baseUrl : String
baseUrl =
    "http://localhost:8001"


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
