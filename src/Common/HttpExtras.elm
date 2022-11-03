module Common.HttpExtras exposing (expectRawBytes)

import Bytes exposing (Bytes)
import Http


{-| A lame Http.Expect handler that returns either a generic error message or
the raw bytes of the response. Intended exclusively for handling media files.
-}
expectRawBytes : (Result String Bytes -> msg) -> Http.Expect msg
expectRawBytes toMsg =
    Http.expectBytesResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ _ ->
                    Err "Failed to process server URL. This is a bug. If you have the time, please report it!"

                Http.Timeout_ ->
                    Err "A timeout occurred while contacting the server. It may be down or under heavy load. Try again in a moment."

                Http.NetworkError_ ->
                    Err "A network error occurred."

                Http.BadStatus_ metadata _ ->
                    Err ("A network error occurred (status " ++ String.fromInt metadata.statusCode ++ ").")

                Http.GoodStatus_ _ body ->
                    Ok body
