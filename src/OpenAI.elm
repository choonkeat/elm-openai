module OpenAI exposing (withConfig, Config)

{-| This package is NOT intended to be run on the browser since `apiKey` will be exposed. Call it from a server like [elm-webapp](https://github.com/choonkeat/elm-webapp) or [lamdera.com](https://lamdera.com) instead.

    OpenAI.Edits.createEdits input
        |> OpenAI.withConfig cfg
        |> Http.task

See <https://beta.openai.com/docs/api-reference/introduction>

@docs withConfig, Config

-}

import Ext.Http
import Http


{-| -}
type alias Config =
    { organizationId : String
    , apiKey : String
    , baseUrl : Maybe String
    }


{-| Add necessary headers to authorize a http request to OpenAI.
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
