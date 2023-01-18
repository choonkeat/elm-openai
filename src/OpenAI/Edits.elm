module OpenAI.Edits exposing
    ( create
    , Input, Output, Choice
    )

{-|

> Given a prompt and an instruction, the model will return an edited version of the prompt.

See <https://beta.openai.com/docs/api-reference/edits>

@docs create

@docs Input, Output, Choice

-}

import Ext.Http
import Http
import Json.Decode
import Json.Encode
import OpenAI.Common
import OpenAI.Internal
import OpenAI.ModelID
import Time


{-| -}
type alias Input =
    { model : OpenAI.ModelID.ModelID
    , input : String
    , instruction : String
    , n : Maybe Int
    , temperature : Maybe Float
    , top_p : Maybe Float
    }


encodeInput : Input -> Json.Encode.Value
encodeInput input =
    Json.Encode.object
        (List.filterMap identity
            [ Just ( "model", Json.Encode.string (OpenAI.ModelID.stringFromModelID input.model) )
            , Just ( "input", Json.Encode.string input.input )
            , Just ( "instruction", Json.Encode.string input.instruction )
            , Maybe.map (\a -> ( "n", Json.Encode.int a )) input.n
            , Maybe.map (\a -> ( "temperature", Json.Encode.float a )) input.temperature
            , Maybe.map (\a -> ( "top_p", Json.Encode.float a )) input.top_p
            ]
        )


{-| -}
type alias Output =
    { object : String
    , created : Time.Posix
    , usage : OpenAI.Common.Usage
    , choices : List Choice
    }


decodeOutput : Json.Decode.Decoder Output
decodeOutput =
    Json.Decode.map4 Output
        (Json.Decode.field "object" Json.Decode.string)
        (Json.Decode.field "created" OpenAI.Internal.decodeUnixTimeAsTimePosix)
        (Json.Decode.field "usage" OpenAI.Internal.decodeUsage)
        (Json.Decode.field "choices" (Json.Decode.list decodeChoice))


{-| -}
type alias Choice =
    { text : String
    , index : Int
    }


decodeChoice : Json.Decode.Decoder Choice
decodeChoice =
    Json.Decode.map2 Choice
        (Json.Decode.field "text" Json.Decode.string)
        (Json.Decode.field "index" Json.Decode.int)


{-| <https://beta.openai.com/docs/api-reference/edits/create>

    create
        { model = OpenAI.ModelID.TextDavinciEdit001
        , input = "The quick brown fox jumps over the lazy dog."
        , instruction = "Make it more formal."
        , n = Just 2
        , temperature = Nothing
        , top_p = Nothing
        }
        |> OpenAI.withConfig cfg
        |> Http.task
    --> Task.succeed
    -->     { choices =
    -->         [ { index = 0, text = "The quick brown fox jumps over the lazy dog.\nOne day she was on the roof\nLooking for one thing that the the chicken stole.\nIt was long green and has a big nose.\n" }
    -->         , { index = 1, text = "The quick brown fox jumps over the lazy dog. I am going to Germany tonight.\n" }
    -->         ]
    -->     , created = Posix ...
    -->     , object = "edit"
    -->     , usage = { completion_tokens = 79, prompt_tokens = 27, total_tokens = 106 }
    -->     }

-}
create : Input -> Ext.Http.TaskInput (Ext.Http.Error String) Output
create input =
    { method = "POST"
    , headers = []
    , url = "/edits"
    , body = Http.jsonBody (encodeInput input)
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeOutput >> Result.map .data)
    , timeout = Nothing
    }
