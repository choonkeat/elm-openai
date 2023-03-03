module OpenAI.Audio exposing
    ( createTranscription, createTranslation
    , Model(..), Output, ResponseFormat(..), TranscriptionInput, TranslationInput
    )

{-| <https://platform.openai.com/docs/api-reference/audio>

@docs createTranscription, createTranslation

@docs Model, Output, ResponseFormat, TranscriptionInput, TranslationInput

-}

import Ext.Http
import File
import Http
import Json.Decode
import OpenAI.Common
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
    { file : File.File
    , model : Model
    , prompt : Maybe String
    , response_format : Maybe ResponseFormat
    , temperature : Maybe Float
    , language : Maybe String
    }


formEncodeTranscriptionInput : TranscriptionInput -> List Http.Part
formEncodeTranscriptionInput input =
    List.filterMap identity
        [ Just (Http.stringPart "model" (stringFromModel input.model))
        , Just (Http.filePart "file" input.file)
        , Maybe.map (\a -> Http.stringPart "prompt" a) input.prompt
        , Maybe.map (\a -> Http.stringPart "response_format" (stringFromResponseFormat a)) input.response_format
        , Maybe.map (\a -> Http.stringPart "temperature" (String.fromFloat a)) input.temperature
        , Maybe.map (\a -> Http.stringPart "language" a) input.language
        ]


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
    , body = Http.multipartBody (formEncodeTranscriptionInput input)
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeOutput >> Result.map .data)
    , timeout = Nothing
    }


{-| -}
type alias TranslationInput =
    { file : File.File
    , model : Model
    , prompt : Maybe String
    , response_format : Maybe ResponseFormat
    , temperature : Maybe Float
    }


formEncodeTranslationInput : TranslationInput -> List Http.Part
formEncodeTranslationInput input =
    List.filterMap identity
        [ Just (Http.stringPart "model" (stringFromModel input.model))
        , Just (Http.filePart "file" input.file)
        , Maybe.map (\a -> Http.stringPart "prompt" a) input.prompt
        , Maybe.map (\a -> Http.stringPart "response_format" (stringFromResponseFormat a)) input.response_format
        , Maybe.map (\a -> Http.stringPart "temperature" (String.fromFloat a)) input.temperature
        ]


{-| <https://platform.openai.com/docs/api-reference/audio/create>
-}
createTranslation : TranslationInput -> Ext.Http.TaskInput (Ext.Http.Error String) Output
createTranslation input =
    { method = "POST"
    , headers = []
    , url = "/audio/translations"
    , body = Http.multipartBody (formEncodeTranslationInput input)
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeOutput >> Result.map .data)
    , timeout = Nothing
    }
