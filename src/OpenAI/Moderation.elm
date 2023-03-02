module OpenAI.Moderation exposing
    ( create
    , Input, Model(..), Output, Moderation, Category, CategoryScore
    )

{-|

> The moderation endpoint is a tool you can use to check whether content complies with OpenAI's content policy. Developers can thus identify content that our content policy prohibits and take action, for instance by filtering it.

See <https://beta.openai.com/docs/guides/moderation/overview>

@docs create

@docs Input, Model, Output, Moderation, Category, CategoryScore

-}

import Ext.Http
import Http
import Json.Decode
import Json.Encode
import OpenAI.Internal exposing (andMap)
import OpenAI.ModelID


{-| -}
type Model
    = TextModerationStable
    | TextModerationLatest


stringFromModel : Model -> String
stringFromModel s =
    case s of
        TextModerationStable ->
            "text-moderation-stable"

        TextModerationLatest ->
            "text-moderation-latest"


{-| -}
type alias Input =
    { input : String
    , model : Maybe Model
    }


encodeInput : Input -> Json.Encode.Value
encodeInput input =
    Json.Encode.object
        (List.filterMap identity
            [ Just ( "input", Json.Encode.string input.input )
            , Maybe.map (\a -> ( "model", Json.Encode.string (stringFromModel a) )) input.model
            ]
        )


{-| -}
type alias Output =
    { id : String
    , model : OpenAI.ModelID.ModelID
    , results : List Moderation
    }


decodeOutput : Json.Decode.Decoder Output
decodeOutput =
    Json.Decode.succeed Output
        |> andMap (Json.Decode.field "id" Json.Decode.string)
        |> andMap (Json.Decode.field "model" (Json.Decode.string |> Json.Decode.map OpenAI.ModelID.modelIDFromString))
        |> andMap (Json.Decode.field "results" (Json.Decode.list decodeModeration))


{-| -}
type alias Category =
    { hate : Bool
    , hate_threatening : Bool
    , self_harm : Bool
    , sexual : Bool
    , sexual_minors : Bool
    , violence : Bool
    , violence_graphic : Bool
    }


decodeCategory : Json.Decode.Decoder Category
decodeCategory =
    Json.Decode.succeed Category
        |> andMap (Json.Decode.field "hate" Json.Decode.bool)
        |> andMap (Json.Decode.field "hate/threatening" Json.Decode.bool)
        |> andMap (Json.Decode.field "self-harm" Json.Decode.bool)
        |> andMap (Json.Decode.field "sexual" Json.Decode.bool)
        |> andMap (Json.Decode.field "sexual/minors" Json.Decode.bool)
        |> andMap (Json.Decode.field "violence" Json.Decode.bool)
        |> andMap (Json.Decode.field "violence/graphic" Json.Decode.bool)


{-| -}
type alias CategoryScore =
    { hate : Float
    , hate_threatening : Float
    , self_harm : Float
    , sexual : Float
    , sexual_minors : Float
    , violence : Float
    , violence_graphic : Float
    }


decodeCategoryScore : Json.Decode.Decoder CategoryScore
decodeCategoryScore =
    Json.Decode.succeed CategoryScore
        |> andMap (Json.Decode.field "hate" Json.Decode.float)
        |> andMap (Json.Decode.field "hate/threatening" Json.Decode.float)
        |> andMap (Json.Decode.field "self-harm" Json.Decode.float)
        |> andMap (Json.Decode.field "sexual" Json.Decode.float)
        |> andMap (Json.Decode.field "sexual/minors" Json.Decode.float)
        |> andMap (Json.Decode.field "violence" Json.Decode.float)
        |> andMap (Json.Decode.field "violence/graphic" Json.Decode.float)


{-| -}
type alias Moderation =
    { categories : Category
    , category_scores : CategoryScore
    , flagged : Bool
    }


decodeModeration : Json.Decode.Decoder Moderation
decodeModeration =
    Json.Decode.succeed Moderation
        |> andMap (Json.Decode.field "categories" decodeCategory)
        |> andMap (Json.Decode.field "category_scores" decodeCategoryScore)
        |> andMap (Json.Decode.field "flagged" Json.Decode.bool)


{-| <https://beta.openai.com/docs/api-reference/moderations/create>

    create
        { input = "I ** you"
        , model = Just TextModerationLatest
        }
        |> OpenAI.withConfig cfg
        |> Http.task
    -- > Task.succeed
    -- >     { id = "modr-6a5SyUXa0D954a3h9hHi737O8vtM3"
    -- >     , model = Custom "text-moderation-004"
    -- >     , results =
    -- >         [ { categories = { hate = False, hate_threatening = False, self_harm = False, sexual = False, sexual_minors = False, violence = False, violence_graphic = False }
    -- >           , category_scores = { hate = 0.000005618692284770077, hate_threatening = 7.34394856038989e-9, self_harm = 1.334657184770549e-7, sexual = 0.001665698830038309, sexual_minors = 7.969669013618841e-7, violence = 0.000050713490054477006, violence_graphic = 4.190181073226995e-7 }
    -- >           , flagged = False
    -- >           }
    -- >         ]
    -- >     }

-}
create : Input -> Ext.Http.TaskInput (Ext.Http.Error String) Output
create input =
    { method = "POST"
    , headers = []
    , url = "/moderations"
    , body = Http.jsonBody (encodeInput input)
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver decodeOutput >> Result.map .data)
    , timeout = Nothing
    }
