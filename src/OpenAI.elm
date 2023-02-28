module OpenAI exposing (Config, withConfig)

{-| This package is NOT intended to be run on the browser since `apiKey` will be exposed. Call it from a server like [elm-webapp](https://github.com/choonkeat/elm-webapp) or [lamdera.com](https://lamdera.com) instead.

    OpenAI.Edits.createEdits input
        |> OpenAI.withConfig cfg
        |> Http.task

See <https://beta.openai.com/docs/api-reference/introduction>

@docs Config, withConfig

-}

import Ext.Http
import Http


{-|

> The OpenAI API uses API keys for authentication. Visit your [API Keys page](https://platform.openai.com/account/api-keys) to retrieve the **API key** you'll use in your requests.

> **Organization IDs** can be found on your [Organization settings page](https://platform.openai.com/account/org-settings).

<https://platform.openai.com/docs/api-reference/authentication>

In your index.js, pass these values as flags to your Elm app

    const app = Elm.MyApp.init({
        flags: {
            openaiConfig: {
                apiKey: process.env.OPENAI_API_KEY,
                organizationId: process.env.OPENAI_ORG_ID,
                baseUrl: process.env.OPENAI_BASE_URL || null
            }
        }
    });

In your server Main.elm, the values will be passed in as a `OpenAI.Config` record

    init : { openaiConfig : OpenAI.Config } -> ( Model, Cmd Msg )
    init flags =
        ( model
        , OpenAI.Model.listModels
            |> OpenAI.withConfig flags.openaiConfig
            |> Http.task
            |> Task.attempt Done
        )

-}
type alias Config =
    { organizationId : String
    , apiKey : String
    , baseUrl : Maybe String
    }


{-| <https://platform.openai.com/docs/api-reference/making-requests>

Add necessary headers to authorize a http request to OpenAI. This is a necessary step before calling [`Http.task`](https://package.elm-lang.org/packages/elm/http/latest/Http#task).

    create
        { model = OpenAI.ModelID.TextEmbeddingAda002
        , input = "The food was delicious and the waiter..."
        , user = Nothing
        }
        |> OpenAI.withConfig cfg
        |> Http.task

-}
withConfig : Config -> Ext.Http.TaskInput x a -> Ext.Http.TaskInput x a
withConfig config req =
    { req
        | url = Maybe.withDefault "https://api.openai.com/v1" config.baseUrl ++ req.url
        , headers =
            req.headers
                ++ [ Http.header "Authorization" ("Bearer " ++ config.apiKey)
                   , Http.header "OpenAI-Organization" config.organizationId
                   ]
    }
