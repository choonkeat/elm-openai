module OpenAI.FineTune exposing
    ( create, get, list, listEvents, cancel, delete
    , Input, BaseModel(..), FineTune, HyperParameters, JobStatus(..), Event
    )

{-|

> Fine-tuning lets you get more out of the models available through the API by providing:
>
>   - Higher quality results than prompt design
>   - Ability to train on more examples than can fit in a prompt
>   - Token savings due to shorter prompts
>   - Lower latency requests

See <https://beta.openai.com/docs/guides/fine-tuning>

@docs create, get, list, listEvents, cancel, delete

@docs Input, BaseModel, FineTune, HyperParameters, JobStatus, Event

-}

import Ext.Http
import Http
import Json.Decode
import Json.Encode
import OpenAI.Common
import OpenAI.Internal exposing (andMap)
import OpenAI.ModelID
import Time


{-| The name of the base model to fine-tune. You can select one of "ada", "babbage", "curie", "davinci", or a fine-tuned model created after 2022-04-21. To learn more about these models, see the Models documentation.
-}
type BaseModel
    = Ada
    | Babbage
    | Curie
    | Davinci
    | FineTuned String


stringFromBaseModel : BaseModel -> String
stringFromBaseModel model =
    case model of
        Ada ->
            "ada"

        Babbage ->
            "babbage"

        Curie ->
            "curie"

        Davinci ->
            "davinci"

        FineTuned str ->
            str


{-| -}
type alias Input =
    { training_file_id : String
    , validation_file : Maybe String
    , model : Maybe BaseModel
    , n_epochs : Maybe Int
    , batch_size : Maybe Int
    , learning_rate_multiplier : Maybe Float
    , prompt_loss_weight : Maybe Float
    , compute_classification_metrics : Maybe Bool
    , classification_n_classes : Maybe Int
    , classification_positive_class : Maybe String
    , classification_betas : Maybe (List Float)
    , suffix : Maybe String
    }


encodeInput : Input -> Json.Encode.Value
encodeInput input =
    Json.Encode.object
        (List.filterMap identity
            [ Just ( "training_file_id", Json.Encode.string input.training_file_id )
            , Maybe.map (\a -> ( "validation_file", Json.Encode.string a )) input.validation_file
            , Maybe.map (\a -> ( "model", Json.Encode.string (stringFromBaseModel a) )) input.model
            , Maybe.map (\a -> ( "n_epochs", Json.Encode.int a )) input.n_epochs
            , Maybe.map (\a -> ( "batch_size", Json.Encode.int a )) input.batch_size
            , Maybe.map (\a -> ( "learning_rate_multiplier", Json.Encode.float a )) input.learning_rate_multiplier
            , Maybe.map (\a -> ( "prompt_loss_weight", Json.Encode.float a )) input.prompt_loss_weight
            , Maybe.map (\a -> ( "compute_classification_metrics", Json.Encode.bool a )) input.compute_classification_metrics
            , Maybe.map (\a -> ( "classification_n_classes", Json.Encode.int a )) input.classification_n_classes
            , Maybe.map (\a -> ( "classification_positive_class", Json.Encode.string a )) input.classification_positive_class
            , Maybe.map (\a -> ( "classification_betas", Json.Encode.list Json.Encode.float a )) input.classification_betas
            , Maybe.map (\a -> ( "suffix", Json.Encode.string a )) input.suffix
            ]
        )


{-| -}
type alias Event =
    { object : String
    , created_at : Time.Posix
    , level : String
    , message : String
    }


decodeEvent : Json.Decode.Decoder Event
decodeEvent =
    Json.Decode.map4 Event
        (Json.Decode.field "object" Json.Decode.string)
        (Json.Decode.field "created_at" OpenAI.Internal.decodeUnixTimeAsTimePosix)
        (Json.Decode.field "level" Json.Decode.string)
        (Json.Decode.field "message" Json.Decode.string)


{-| -}
type alias HyperParameters =
    { batch_size : Int
    , learning_rate_multiplier : Float
    , n_epochs : Int
    , prompt_loss_weight : Float
    }


decodeHyperParameters : Json.Decode.Decoder HyperParameters
decodeHyperParameters =
    Json.Decode.map4 HyperParameters
        (Json.Decode.field "batch_size" Json.Decode.int)
        (Json.Decode.field "learning_rate_multiplier" Json.Decode.float)
        (Json.Decode.field "n_epochs" Json.Decode.int)
        (Json.Decode.field "prompt_loss_weight" Json.Decode.float)


{-| -}
type JobStatus
    = Pending
    | Succeeded
    | Cancelled
    | Other String


decodeJobStatus : Json.Decode.Decoder JobStatus
decodeJobStatus =
    Json.Decode.string
        |> Json.Decode.map
            (\str ->
                case str of
                    "pending" ->
                        Pending

                    "succeeded" ->
                        Succeeded

                    "cancelled" ->
                        Cancelled

                    other ->
                        Other other
            )


{-| -}
type alias FineTune =
    { id : String
    , object : String
    , model : OpenAI.ModelID.ModelID
    , created_at : Time.Posix
    , events : List Event
    , fine_tuned_model : Maybe String
    , hyperparams : HyperParameters
    , organization_id : String
    , result_files : List OpenAI.Common.File
    , status : JobStatus
    , validation_files : List OpenAI.Common.File
    , training_files : List OpenAI.Common.File
    , updated_at : Time.Posix
    }


decodeFineTune : Json.Decode.Decoder FineTune
decodeFineTune =
    Json.Decode.succeed FineTune
        |> andMap (Json.Decode.field "id" Json.Decode.string)
        |> andMap (Json.Decode.field "object" Json.Decode.string)
        |> andMap (Json.Decode.field "model" (Json.Decode.string |> Json.Decode.map OpenAI.ModelID.modelIDFromString))
        |> andMap (Json.Decode.field "created_at" OpenAI.Internal.decodeUnixTimeAsTimePosix)
        |> andMap (Json.Decode.field "events" (Json.Decode.list decodeEvent))
        |> andMap (Json.Decode.field "fine_tuned_model" (Json.Decode.maybe Json.Decode.string))
        |> andMap (Json.Decode.field "hyperparams" decodeHyperParameters)
        |> andMap (Json.Decode.field "organization_id" Json.Decode.string)
        |> andMap (Json.Decode.field "result_files" (Json.Decode.list OpenAI.Internal.decodeFile))
        |> andMap (Json.Decode.field "status" decodeJobStatus)
        |> andMap (Json.Decode.field "validation_files" (Json.Decode.list OpenAI.Internal.decodeFile))
        |> andMap (Json.Decode.field "training_files" (Json.Decode.list OpenAI.Internal.decodeFile))
        |> andMap (Json.Decode.field "updated_at" OpenAI.Internal.decodeUnixTimeAsTimePosix)


{-| <https://beta.openai.com/docs/api-reference/fine-tunes/create>
-}
create : Input -> Ext.Http.TaskInput (Ext.Http.Error String) FineTune
create input =
    { method = "POST"
    , headers = []
    , url = "/fine-tunes"
    , body = Http.jsonBody (encodeInput input)
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeFineTune >> Result.map .data)
    , timeout = Nothing
    }


{-| <https://beta.openai.com/docs/api-reference/fine-tunes/list>
-}
list : Ext.Http.TaskInput (Ext.Http.Error String) (List FineTune)
list =
    { method = "GET"
    , headers = []
    , url = "/fine-tunes"
    , body = Http.emptyBody
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver (Json.Decode.field "data" (Json.Decode.list decodeFineTune)) >> Result.map .data)
    , timeout = Nothing
    }


{-| <https://beta.openai.com/docs/api-reference/fine-tunes/retrieve>
-}
get : OpenAI.ModelID.ModelID -> Ext.Http.TaskInput (Ext.Http.Error String) FineTune
get fine_tune_id =
    { method = "GET"
    , headers = []
    , url = "/fine-tunes/" ++ OpenAI.ModelID.stringFromModelID fine_tune_id
    , body = Http.emptyBody
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeFineTune >> Result.map .data)
    , timeout = Nothing
    }


{-| <https://beta.openai.com/docs/api-reference/fine-tunes/cancel>
-}
cancel : OpenAI.ModelID.ModelID -> Ext.Http.TaskInput (Ext.Http.Error String) FineTune
cancel fine_tune_id =
    { method = "POST"
    , headers = []
    , url = "/fine-tunes/" ++ OpenAI.ModelID.stringFromModelID fine_tune_id
    , body = Http.emptyBody
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeFineTune >> Result.map .data)
    , timeout = Nothing
    }


{-| <https://beta.openai.com/docs/api-reference/fine-tunes/events>
-}
listEvents : OpenAI.ModelID.ModelID -> Ext.Http.TaskInput (Ext.Http.Error String) (List Event)
listEvents fine_tune_id =
    { method = "GET"
    , headers = []
    , url = "/fine-tunes/" ++ OpenAI.ModelID.stringFromModelID fine_tune_id ++ "/events"
    , body = Http.emptyBody
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver (Json.Decode.field "data" (Json.Decode.list decodeEvent)) >> Result.map .data)
    , timeout = Nothing
    }


{-| <https://beta.openai.com/docs/api-reference/fine-tunes/delete-model>
-}
delete : OpenAI.ModelID.ModelID -> Ext.Http.TaskInput (Ext.Http.Error String) OpenAI.Common.DeleteOutput
delete model_id =
    { method = "DELETE"
    , headers = []
    , url = "/models/" ++ OpenAI.ModelID.stringFromModelID model_id
    , body = Http.emptyBody
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver OpenAI.Internal.decodeDeleteOutput >> Result.map .data)
    , timeout = Nothing
    }
