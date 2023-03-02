module OpenAI.Embeddings exposing
    ( create
    , Input, Output, Data, Usage
    )

{-|

> OpenAI’s text embeddings measure the relatedness of text strings. Embeddings are most commonly used for:
>
>   - Search (where results are ranked by relevance to a query string)
>   - Clustering (where text strings are grouped by similarity)
>   - Recommendations (where items with related text strings are recommended)
>   - Anomaly detection (where outliers with little relatedness are identified)
>   - Diversity measurement (where similarity distributions are analyzed)
>   - Classification (where text strings are classified by their most similar label)
>
> An embedding is a vector (list) of floating point numbers. The distance between two vectors measures their relatedness. Small distances suggest high relatedness and large distances suggest low relatedness.

See <https://beta.openai.com/docs/guides/embeddings>

@docs create

@docs Input, Output, Data, Usage

-}

import Ext.Http
import Http
import Json.Decode
import Json.Encode
import OpenAI.ModelID


{-| -}
type alias Input =
    { model : OpenAI.ModelID.ModelID
    , input : String
    , user : Maybe String
    }


encodeInput : Input -> Json.Encode.Value
encodeInput input =
    Json.Encode.object
        (List.filterMap identity
            [ Just ( "model", Json.Encode.string (OpenAI.ModelID.stringFromModelID input.model) )
            , Just ( "input", Json.Encode.string input.input )
            , Maybe.map (\a -> ( "user", Json.Encode.string a )) input.user
            ]
        )


{-| -}
type alias Data =
    { object : String
    , index : Int
    , embedding : List Float
    }


decodeData : Json.Decode.Decoder Data
decodeData =
    Json.Decode.map3 Data
        (Json.Decode.field "object" Json.Decode.string)
        (Json.Decode.field "index" Json.Decode.int)
        (Json.Decode.field "embedding" (Json.Decode.list Json.Decode.float))


{-| -}
type alias Output =
    { object : String
    , data : List Data
    , model : OpenAI.ModelID.ModelID
    , usage : Usage
    }


{-| -}
type alias Usage =
    { prompt_tokens : Int
    , total_tokens : Int
    }


decodeUsage : Json.Decode.Decoder Usage
decodeUsage =
    Json.Decode.map2 Usage
        (Json.Decode.field "prompt_tokens" Json.Decode.int)
        (Json.Decode.field "total_tokens" Json.Decode.int)


decodeOutput : Json.Decode.Decoder Output
decodeOutput =
    Json.Decode.map4 Output
        (Json.Decode.field "object" Json.Decode.string)
        (Json.Decode.field "data" (Json.Decode.list decodeData))
        (Json.Decode.field "model" (Json.Decode.string |> Json.Decode.map OpenAI.ModelID.modelIDFromString))
        (Json.Decode.field "usage" decodeUsage)


{-| <https://beta.openai.com/docs/api-reference/embeddings/create>

    create
        { model = OpenAI.ModelID.TextEmbeddingAda002
        , input = "The food was delicious and the waiter..."
        , user = Nothing
        }
        |> OpenAI.withConfig cfg
        |> Http.task
    -- > Task.succeed
    -- >     { data =
    -- >         [ { embedding = [0.0023064255,-0.009327292,...,-0.0028842222 ]
    -- >           , index = 0
    -- >           , object = "embedding"
    -- >           }
    -- >         ]
    -- >     , model = Custom "text-embedding-ada-002-v2"
    -- >     , object = "list"
    -- >     , usage = { prompt_tokens = 8, total_tokens = 8 }
    -- >     }

-}
create : Input -> Ext.Http.TaskInput (Ext.Http.Error String) Output
create input =
    { method = "POST"
    , headers = []
    , url = "/embeddings"
    , body = Http.jsonBody (encodeInput input)
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeOutput >> Result.map .data)
    , timeout = Nothing
    }
