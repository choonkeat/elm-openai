module OpenAI.Image exposing
    ( create, createEdit, createVariation
    , Input, EditsInput, ResponseFormat(..), Size(..), Output(..)
    )

{-|

> The Images API provides three methods for interacting with images:
>
>   - Creating images from scratch based on a text prompt
>   - Creating edits of an existing image based on a new text prompt
>   - Creating variations of an existing image

See <https://beta.openai.com/docs/guides/images>

@docs create, createEdit, createVariation

@docs Input, EditsInput, ResponseFormat, Size, Output

-}

import Bytes exposing (Bytes)
import Ext.Http
import Http
import Json.Decode
import Json.Encode
import OpenAI.Common
import OpenAI.Internal
import Time
import Url


{-| <https://beta.openai.com/docs/api-reference/images/create>
-}
create : Input -> Ext.Http.TaskInput (Ext.Http.Error String) Output
create input =
    { method = "POST"
    , headers = []
    , url = "/images/generations"
    , body = Http.jsonBody (encodeInput input)
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeOutput >> Result.map .data)
    , timeout = Nothing
    }


{-| -}
type Size
    = Size256x256
    | Size512x512
    | Size1024x1024


{-| -}
stringFromSize : Size -> String
stringFromSize dim =
    case dim of
        Size256x256 ->
            "256x256"

        Size512x512 ->
            "512x512"

        Size1024x1024 ->
            "1024x1024"


{-| -}
encodeSize : Size -> Json.Encode.Value
encodeSize dim =
    Json.Encode.string (stringFromSize dim)


{-| -}
type ResponseFormat
    = ImageURL
    | ImageB64Json


{-| -}
stringFromResponseFormat : ResponseFormat -> String
stringFromResponseFormat format =
    case format of
        ImageURL ->
            "url"

        ImageB64Json ->
            "b64_json"


encodeResponseFormat : ResponseFormat -> Json.Encode.Value
encodeResponseFormat format =
    Json.Encode.string (stringFromResponseFormat format)


{-| -}
type alias Input =
    { prompt : String
    , n : Maybe Int
    , size : Maybe Size
    , response_format : Maybe ResponseFormat
    , user : Maybe String
    }


encodeInput : Input -> Json.Encode.Value
encodeInput input =
    Json.Encode.object
        (List.filterMap identity
            [ Just ( "prompt", Json.Encode.string input.prompt )
            , Maybe.map (\a -> ( "n", Json.Encode.int a )) input.n
            , Maybe.map (\a -> ( "size", encodeSize a )) input.size
            , Maybe.map (\a -> ( "response_format", encodeResponseFormat a )) input.response_format
            , Maybe.map (\a -> ( "user", Json.Encode.string a )) input.user
            ]
        )


{-| -}
type Output
    = ImageURLOutput Time.Posix (List Url.Url)
    | ImageB64JsonOutput Time.Posix (List Bytes)


decodeOutput : Json.Decode.Decoder Output
decodeOutput =
    Json.Decode.oneOf
        [ Json.Decode.map2 ImageURLOutput
            (Json.Decode.field "created" OpenAI.Internal.decodeUnixTimeAsTimePosix)
            (Json.Decode.field "data" (Json.Decode.list (Json.Decode.field "url" OpenAI.Internal.decodeUrl)))
        , Json.Decode.map2 ImageB64JsonOutput
            (Json.Decode.field "created" OpenAI.Internal.decodeUnixTimeAsTimePosix)
            (Json.Decode.field "data" (Json.Decode.list (Json.Decode.field "b64_json" OpenAI.Internal.decodeBase64)))
        ]


{-| -}
type alias EditsInput =
    { image : OpenAI.Common.BinaryBlob
    , mask : Maybe OpenAI.Common.BinaryBlob
    , prompt : String
    , n : Maybe Int
    , size : Maybe Size
    , response_format : Maybe ResponseFormat
    , user : Maybe String
    }


{-| <https://beta.openai.com/docs/api-reference/images/create-edit>
-}
createEdit : EditsInput -> Ext.Http.TaskInput (Ext.Http.Error String) Output
createEdit input =
    { method = "POST"
    , headers = []
    , url = "/images/edits"
    , body = Http.multipartBody (formEncodeEditsInput input)
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeOutput >> Result.map .data)
    , timeout = Nothing
    }


formEncodeEditsInput : EditsInput -> List Http.Part
formEncodeEditsInput input =
    List.filterMap identity
        [ Just (Http.stringPart "prompt" input.prompt)
        , Maybe.map (\a -> Http.stringPart "n" (String.fromInt a)) input.n
        , Maybe.map (\a -> Http.stringPart "size" (stringFromSize a)) input.size
        , Maybe.map (\a -> Http.stringPart "response_format" (stringFromResponseFormat a)) input.response_format
        , Maybe.map (\a -> Http.stringPart "user" a) input.user
        , Just (Http.bytesPart "image" input.image.contentType input.image.bytes)
        , Maybe.map (\a -> Http.bytesPart "mask" a.contentType a.bytes) input.mask
        ]


{-| -}
type alias ImageVariationInput =
    { image : OpenAI.Common.BinaryBlob
    , n : Maybe Int
    , size : Maybe Size
    , response_format : Maybe ResponseFormat
    , user : Maybe String
    }


{-| <https://beta.openai.com/docs/api-reference/images/create-variation>
-}
createVariation : ImageVariationInput -> Ext.Http.TaskInput (Ext.Http.Error String) Output
createVariation input =
    { method = "POST"
    , headers = []
    , url = "/images/variations"
    , body = Http.multipartBody (formEncodeImageVariationInput input)
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeOutput >> Result.map .data)
    , timeout = Nothing
    }


formEncodeImageVariationInput : ImageVariationInput -> List Http.Part
formEncodeImageVariationInput input =
    List.filterMap identity
        [ Maybe.map (\a -> Http.stringPart "n" (String.fromInt a)) input.n
        , Maybe.map (\a -> Http.stringPart "size" (stringFromSize a)) input.size
        , Maybe.map (\a -> Http.stringPart "response_format" (stringFromResponseFormat a)) input.response_format
        , Maybe.map (\a -> Http.stringPart "user" a) input.user
        , Just (Http.bytesPart "image" input.image.contentType input.image.bytes)
        ]
