module OpenAI.Completion exposing
    ( create
    , Input, Output, Choice, Logprob
    )

{-|

> Given a prompt, the model will return one or more predicted completions, and can also return the probabilities of alternative tokens at each position.

See <https://beta.openai.com/docs/api-reference/completions>

@docs create

@docs Input, Output, Choice, Logprob

-}

import Dict exposing (Dict)
import Ext.Http
import Http
import Json.Decode
import Json.Encode
import OpenAI.Common
import OpenAI.Internal
import OpenAI.ModelID
import Time


{-| If `stream` is set to `True`, partial message deltas will be sent, like in ChatGPT. Tokens will be sent as data-only server-sent events as they become available, with the stream terminated by a `data: [DONE]` message. This is unsupported in this library for now
-}
type alias Input =
    { model : OpenAI.ModelID.ModelID
    , prompt : String
    , suffix : Maybe String
    , max_tokens : Maybe Int
    , temperature : Maybe Float
    , top_p : Maybe Float
    , n : Maybe Int
    , stream : Maybe Bool
    , logprobs : Maybe Int
    , echo : Maybe Bool
    , stop : Maybe (List String)
    , presence_penalty : Maybe Float
    , frequency_penalty : Maybe Float
    , best_of : Maybe Int
    , logit_bias : Maybe (Dict String Int)
    , user : Maybe String
    }


encodeInput : Input -> Json.Encode.Value
encodeInput input =
    Json.Encode.object
        (List.filterMap identity
            [ Just ( "model", Json.Encode.string (OpenAI.ModelID.stringFromModelID input.model) )
            , Just ( "prompt", Json.Encode.string input.prompt )
            , Maybe.map (\a -> ( "suffix", Json.Encode.string a )) input.suffix
            , Maybe.map (\a -> ( "max_tokens", Json.Encode.int a )) input.max_tokens
            , Maybe.map (\a -> ( "temperature", Json.Encode.float a )) input.temperature
            , Maybe.map (\a -> ( "top_p", Json.Encode.float a )) input.top_p
            , Maybe.map (\a -> ( "n", Json.Encode.int a )) input.n
            , Maybe.map (\a -> ( "stream", Json.Encode.bool a )) input.stream
            , Maybe.map (\a -> ( "logprobs", Json.Encode.int a )) input.logprobs
            , Maybe.map (\a -> ( "echo", Json.Encode.bool a )) input.echo
            , Maybe.map (\a -> ( "stop", Json.Encode.list Json.Encode.string a )) input.stop
            , Maybe.map (\a -> ( "presence_penalty", Json.Encode.float a )) input.presence_penalty
            , Maybe.map (\a -> ( "frequency_penalty", Json.Encode.float a )) input.frequency_penalty
            , Maybe.map (\a -> ( "best_of", Json.Encode.int a )) input.best_of
            , Maybe.map (\a -> ( "logit_bias", Json.Encode.dict identity Json.Encode.int a )) input.logit_bias
            , Maybe.map (\a -> ( "user", Json.Encode.string a )) input.user
            ]
        )


{-| -}
type alias Output =
    { id : String
    , object : String
    , created : Time.Posix
    , model : OpenAI.ModelID.ModelID
    , choices : List Choice
    , usage : OpenAI.Common.Usage
    }


decodeOutput : Json.Decode.Decoder Output
decodeOutput =
    Json.Decode.map6 Output
        (Json.Decode.field "id" Json.Decode.string)
        (Json.Decode.field "object" Json.Decode.string)
        (Json.Decode.field "created" OpenAI.Internal.decodeUnixTimeAsTimePosix)
        (Json.Decode.field "model" (Json.Decode.string |> Json.Decode.map OpenAI.ModelID.modelIDFromString))
        (Json.Decode.field "choices" (Json.Decode.list decodeChoice))
        (Json.Decode.field "usage" OpenAI.Internal.decodeUsage)


{-| -}
type alias Choice =
    { text : String
    , index : Int
    , logprobs : Maybe Logprob
    , finish_reason : Maybe String
    }


decodeChoice : Json.Decode.Decoder Choice
decodeChoice =
    Json.Decode.map4 Choice
        (Json.Decode.field "text" Json.Decode.string)
        (Json.Decode.field "index" Json.Decode.int)
        (Json.Decode.field "logprobs" (Json.Decode.maybe decodeLogprob))
        (Json.Decode.field "finish_reason" (Json.Decode.maybe Json.Decode.string))


{-| -}
type alias Logprob =
    { tokens : List String
    , token_logprobs : List Float
    , top_logprobs : Dict String Float
    , text_offset : List Int
    }


decodeLogprob : Json.Decode.Decoder Logprob
decodeLogprob =
    Json.Decode.map4 Logprob
        (Json.Decode.field "tokens" (Json.Decode.list Json.Decode.string))
        (Json.Decode.field "token_logprobs" (Json.Decode.list Json.Decode.float))
        (Json.Decode.field "top_logprobs" (Json.Decode.dict Json.Decode.float))
        (Json.Decode.field "text_offset" (Json.Decode.list Json.Decode.int))


{-| <https://beta.openai.com/docs/api-reference/completions/create>

    create
        { model = OpenAI.ModelID.TextDavinci003
        , prompt = "If I were a farmer's son"
        , suffix = Nothing
        , max_tokens = Nothing
        , temperature = Nothing
        , top_p = Nothing
        , n = Nothing
        , stream = Nothing
        , logprobs = Nothing
        , echo = Nothing
        , stop = Nothing
        , presence_penalty = Nothing
        , frequency_penalty = Nothing
        , best_of = Nothing
        , logit_bias = Nothing
        , user = Nothing
        }
        |> OpenAI.withConfig cfg
        |> Http.task
    --> Task.succeed
    -->     { choices =
    -->         [ { finish_reason = "length"
    -->           , index = 0
    -->           , logprobs = Nothing
    -->           , text = "\n\nIf I were a farmer's son
    -->           , I would rise early each morning"
    -->           }
    -->         ]
    -->     , created = Posix ...
    -->     , id = "cmpl-..."
    -->     , model = TextDavinci003
    -->     , object = "text_completion"
    -->     , usage =
    -->         { completion_tokens = 16
    -->         , prompt_tokens = 7
    -->         , total_tokens = 23
    -->         }
    -->     }

-}
create : Input -> Ext.Http.TaskInput (Ext.Http.Error String) Output
create input =
    { method = "POST"
    , headers = []
    , url = "/completions"
    , body = Http.jsonBody (encodeInput input)
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeOutput >> Result.map .data)
    , timeout = Nothing
    }
