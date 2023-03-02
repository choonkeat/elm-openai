module OpenAI.Audio exposing
    ( createTranscription, createTranslation
    , Model(..), Output, ResponseFormat(..), TranscriptionInput, TranslationInput
    )

{-| <https://platform.openai.com/docs/api-reference/audio>

@docs createTranscription, createTranslation

@docs Model, Output, ResponseFormat, TranscriptionInput, TranslationInput

-}

import Ext.Http
import Http
import Json.Decode
import Json.Encode
import OpenAI.Internal exposing (andMap)


{-| -}
type Model
    = Whisper_1


stringFromModel : Model -> String
stringFromModel model =
    case model of
        Whisper_1 ->
            "whisper-1"


{-| -}
type ResponseFormat
    = JsonFormat
    | VerboseJson
    | TextFormat
    | SrtFormat
    | VttFormat


stringFromResponseFormat : ResponseFormat -> String
stringFromResponseFormat responseFormat =
    case responseFormat of
        JsonFormat ->
            "json"

        VerboseJson ->
            "verbose_json"

        TextFormat ->
            "text"

        SrtFormat ->
            "srt"

        VttFormat ->
            "vtt"


{-| `file`: The the audio file to transcribe, in one of these formats: mp3, mp4, mpeg, mpga, m4a, wav, or webm.

`prompt`: An optional text to guide the model's style or continue a previous audio segment. The prompt should match the audio language.

`language`: The language of the input audio. Supplying the input language in [ISO-639-1 format](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) will improve accuracy and latency.

-}
type alias TranscriptionInput =
    { file : String
    , model : Model
    , prompt : Maybe String
    , response_format : Maybe ResponseFormat
    , temperature : Maybe Float
    , language : Maybe String
    }


encodeTranscriptionInput : TranscriptionInput -> Json.Encode.Value
encodeTranscriptionInput input =
    Json.Encode.object
        (List.filterMap identity
            [ Just ( "file", Json.Encode.string input.file )
            , Just ( "model", Json.Encode.string (stringFromModel input.model) )
            , Maybe.map (\a -> ( "prompt", Json.Encode.string a )) input.prompt
            , Maybe.map (\a -> ( "response_format", Json.Encode.string (stringFromResponseFormat a) )) input.response_format
            , Maybe.map (\a -> ( "temperature", Json.Encode.float a )) input.temperature
            , Maybe.map (\a -> ( "language", Json.Encode.string a )) input.language
            ]
        )


{-| -}
type alias Output =
    { text : String
    }


decodeOutput : Json.Decode.Decoder Output
decodeOutput =
    Json.Decode.succeed Output
        |> andMap (Json.Decode.field "text" Json.Decode.string)


{-| <https://platform.openai.com/docs/api-reference/audio/create>
-}
createTranscription : TranscriptionInput -> Ext.Http.TaskInput (Ext.Http.Error String) Output
createTranscription input =
    { method = "POST"
    , headers = []
    , url = "/audio/transcriptions"
    , body = Http.jsonBody (encodeTranscriptionInput input)
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeOutput >> Result.map .data)
    , timeout = Nothing
    }


{-| -}
type alias TranslationInput =
    { file : String
    , model : Model
    , prompt : Maybe String
    , response_format : Maybe ResponseFormat
    , temperature : Maybe Float
    }


encodeTranslationInput : TranslationInput -> Json.Encode.Value
encodeTranslationInput input =
    Json.Encode.object
        (List.filterMap identity
            [ Just ( "file", Json.Encode.string input.file )
            , Just ( "model", Json.Encode.string (stringFromModel input.model) )
            , Maybe.map (\a -> ( "prompt", Json.Encode.string a )) input.prompt
            , Maybe.map (\a -> ( "response_format", Json.Encode.string (stringFromResponseFormat a) )) input.response_format
            , Maybe.map (\a -> ( "temperature", Json.Encode.float a )) input.temperature
            ]
        )


{-| <https://platform.openai.com/docs/api-reference/audio/create>
-}
createTranslation : TranslationInput -> Ext.Http.TaskInput (Ext.Http.Error String) Output
createTranslation input =
    { method = "POST"
    , headers = []
    , url = "/audio/translations"
    , body = Http.jsonBody (encodeTranslationInput input)
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeOutput >> Result.map .data)
    , timeout = Nothing
    }
