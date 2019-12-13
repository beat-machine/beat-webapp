module Api exposing (Effects, Msg, sendFile)

import File exposing (File)
import Http exposing (filePart, multipartBody, post, stringPart)


baseUrl : String
baseUrl =
    "http://localhost:8001"


type Msg
    = GotSong (Result Http.Error ())


type alias Effects =
    String


sendFile : File -> Effects -> Cmd Msg
sendFile song effects =
    post
        { url = baseUrl
        , body =
            multipartBody
                [ filePart "song" song
                , stringPart "effects" effects
                ]
        , expect = Http.expectWhatever GotSong
        }
