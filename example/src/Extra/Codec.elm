module Extra.Codec exposing (..)

{-| Add custom encoder/decoders here for when encoder/decoders
can't be auto generated
-}

import Json.Decode
import Json.Encode
import OpenAI.Common
import Time


{-| <https://discourse.elm-lang.org/t/about-the-ergonomics-of-applicative-json-decoding>
-}
andMap : Json.Decode.Decoder a -> Json.Decode.Decoder (a -> b) -> Json.Decode.Decoder b
andMap =
    Json.Decode.map2 (|>)


decodeTimePosix : Json.Decode.Decoder Time.Posix
decodeTimePosix =
    Json.Decode.int
        |> Json.Decode.map Time.millisToPosix


encodeTimePosix : Time.Posix -> Json.Encode.Value
encodeTimePosix t =
    Time.posixToMillis t
        |> Json.Encode.int


encodeOpenAICommonFile : OpenAI.Common.File -> Json.Encode.Value
encodeOpenAICommonFile record =
    Json.Encode.object
        [ ( "id", Json.Encode.string record.id )
        , ( "object", Json.Encode.string record.object )
        , ( "bytes", Json.Encode.int record.bytes )
        , ( "created_at", encodeTimePosix record.created_at )
        , ( "filename", Json.Encode.string record.filename )
        , ( "purpose", Json.Encode.string record.purpose )
        ]


decodeOpenAICommonFile : Json.Decode.Decoder OpenAI.Common.File
decodeOpenAICommonFile =
    Json.Decode.succeed OpenAI.Common.File
        |> andMap (Json.Decode.field "id" Json.Decode.string)
        |> andMap (Json.Decode.field "object" Json.Decode.string)
        |> andMap (Json.Decode.field "bytes" Json.Decode.int)
        |> andMap (Json.Decode.field "created_at" decodeTimePosix)
        |> andMap (Json.Decode.field "filename" Json.Decode.string)
        |> andMap (Json.Decode.field "purpose" Json.Decode.string)
