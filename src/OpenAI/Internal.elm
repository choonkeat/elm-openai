module OpenAI.Internal exposing
    ( andMap
    , decodeBase64
    , decodeDeleteOutput
    , decodeFile
    , decodeUnixTimeAsTimePosix
    , decodeUrl
    , decodeUsage
    , decoderFromResult
    )

import Base64
import Bytes exposing (Bytes)
import Json.Decode
import OpenAI.Common
import Time
import Url


{-| Timestamps are encoded in seconds by api.openai.com

    import Json.Encode
    import Json.Decode
    import Time

    millis : List Int
    millis = [ 0, 123456, 1589478378 ]

    millis
    |> List.map Json.Encode.int
    |> List.map (Json.Decode.decodeValue decodeUnixTimeAsTimePosix)
    --> List.map ((*) 1000 >> Time.millisToPosix >> Ok) millis

-}
decodeUnixTimeAsTimePosix : Json.Decode.Decoder Time.Posix
decodeUnixTimeAsTimePosix =
    Json.Decode.int |> Json.Decode.map ((*) 1000 >> Time.millisToPosix)


decodeBase64 : Json.Decode.Decoder Bytes
decodeBase64 =
    Json.Decode.string
        |> Json.Decode.andThen
            (Base64.toBytes
                >> Result.fromMaybe "Invalid Base64"
                >> decoderFromResult
            )


decoderFromResult : Result String a -> Json.Decode.Decoder a
decoderFromResult result =
    case result of
        Ok value ->
            Json.Decode.succeed value

        Err error ->
            Json.Decode.fail error


{-|

    import Json.Encode
    import Json.Decode
    import Url

    urlString : String
    urlString = "http://example.com/hello.txt?world=there"

    Json.Encode.string urlString
        |> Json.Decode.decodeValue decodeUrl
        |> Result.map Url.toString
    --> Ok urlString

-}
decodeUrl : Json.Decode.Decoder Url.Url
decodeUrl =
    Json.Decode.string
        |> Json.Decode.andThen
            (Url.fromString
                >> Result.fromMaybe "Invalid URL"
                >> decoderFromResult
            )


{-| <https://discourse.elm-lang.org/t/about-the-ergonomics-of-applicative-json-decoding>
-}
andMap : Json.Decode.Decoder a -> Json.Decode.Decoder (a -> b) -> Json.Decode.Decoder b
andMap =
    Json.Decode.map2 (|>)


decodeUsage : Json.Decode.Decoder OpenAI.Common.Usage
decodeUsage =
    Json.Decode.map3 OpenAI.Common.Usage
        (Json.Decode.field "prompt_tokens" Json.Decode.int)
        (Json.Decode.field "completion_tokens" Json.Decode.int)
        (Json.Decode.field "total_tokens" Json.Decode.int)


decodeFile : Json.Decode.Decoder OpenAI.Common.File
decodeFile =
    Json.Decode.map6 OpenAI.Common.File
        (Json.Decode.field "id" Json.Decode.string)
        (Json.Decode.field "object" Json.Decode.string)
        (Json.Decode.field "bytes" Json.Decode.int)
        (Json.Decode.field "created_at" decodeUnixTimeAsTimePosix)
        (Json.Decode.field "filename" Json.Decode.string)
        (Json.Decode.field "purpose" Json.Decode.string)


decodeDeleteOutput : Json.Decode.Decoder OpenAI.Common.DeleteOutput
decodeDeleteOutput =
    Json.Decode.map3 OpenAI.Common.DeleteOutput
        (Json.Decode.field "id" Json.Decode.string)
        (Json.Decode.field "object" Json.Decode.string)
        (Json.Decode.field "deleted" Json.Decode.bool)
