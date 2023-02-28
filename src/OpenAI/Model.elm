module OpenAI.Model exposing
    ( getModel, listModels
    , Model, Permission
    )

{-|

> The OpenAI API is powered by a family of models with different capabilities and price points. You can also customize our base models for your specific use case with fine-tuning.

See <https://beta.openai.com/docs/models>

@docs getModel, listModels

@docs Model, Permission

-}

import Ext.Http
import Http
import Json.Decode
import OpenAI.Internal exposing (andMap)
import OpenAI.ModelID
import Time


{-|

> You can refer to the Models documentation to understand what models are available and the differences between them.

<https://platform.openai.com/docs/models>

-}
type alias Model =
    { id : String
    , object : String
    , owned_by : String
    , permission : List Permission
    }


{-| Decodes a `Model` from JSON.
-}
decodeModel : Json.Decode.Decoder Model
decodeModel =
    Json.Decode.map4 Model
        (Json.Decode.field "id" Json.Decode.string)
        (Json.Decode.field "object" Json.Decode.string)
        (Json.Decode.field "owned_by" Json.Decode.string)
        (Json.Decode.field "permission" (Json.Decode.list decodePermission))


{-| <https://beta.openai.com/docs/api-reference/models/list>

Lists the currently available models, and provides basic information about each one such as the owner and availability.

-}
listModels : Ext.Http.TaskInput (Ext.Http.Error String) (List Model)
listModels =
    { method = "GET"
    , headers = []
    , url = "/models"
    , body = Http.emptyBody
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver (Json.Decode.field "data" (Json.Decode.list decodeModel)) >> Result.map .data)
    , timeout = Nothing
    }


{-| <https://beta.openai.com/docs/api-reference/models/retrieve>

Retrieves a model instance, providing basic information about the model such as the owner and permissioning.

-}
getModel : OpenAI.ModelID.ModelID -> Ext.Http.TaskInput (Ext.Http.Error String) Model
getModel modelId =
    { method = "GET"
    , headers = []
    , url = "/models/" ++ OpenAI.ModelID.stringFromModelID modelId
    , body = Http.emptyBody
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeModel >> Result.map .data)
    , timeout = Nothing
    }


{-| -}
type alias Permission =
    { id : String
    , object : String
    , created : Time.Posix
    , allow_create_engine : Bool
    , allow_sampling : Bool
    , allow_logprobs : Bool
    , allow_search_indices : Bool
    , allow_view : Bool
    , allow_fine_tuning : Bool
    , organization : String
    , group : Maybe String
    , is_blocking : Bool
    }


decodePermission : Json.Decode.Decoder Permission
decodePermission =
    Json.Decode.succeed Permission
        |> andMap (Json.Decode.field "id" Json.Decode.string)
        |> andMap (Json.Decode.field "object" Json.Decode.string)
        |> andMap (Json.Decode.field "created" OpenAI.Internal.decodeUnixTimeAsTimePosix)
        |> andMap (Json.Decode.field "allow_create_engine" Json.Decode.bool)
        |> andMap (Json.Decode.field "allow_sampling" Json.Decode.bool)
        |> andMap (Json.Decode.field "allow_logprobs" Json.Decode.bool)
        |> andMap (Json.Decode.field "allow_search_indices" Json.Decode.bool)
        |> andMap (Json.Decode.field "allow_view" Json.Decode.bool)
        |> andMap (Json.Decode.field "allow_fine_tuning" Json.Decode.bool)
        |> andMap (Json.Decode.field "organization" Json.Decode.string)
        |> andMap (Json.Decode.maybe (Json.Decode.field "group" Json.Decode.string))
        |> andMap (Json.Decode.field "is_blocking" Json.Decode.bool)
