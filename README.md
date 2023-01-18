# elm-openai

This is a community-maintained Elm library for [OpenAI API](https://beta.openai.com/docs/api-reference/introduction).

This package is NOT intended to be run on the browser since `apiKey` will be exposed. Call it from the server-side like [elm-webapp](https://github.com/choonkeat/elm-webapp) or [lamdera.com](https://lamdera.com) instead and have the api key stored in environment variables.

See <https://beta.openai.com/docs/api-reference/introduction>

## Usage

```elm
fixSpelling : String -> Task (Ext.Http.Error String) (List OpenAI.Edits.Choice)
fixSpelling userInput =
    let
        cfg =
            { organizationId = "org-123"
            , apiKey = flags.apiKey -- use of environment variables is recommended
            , baseUrl = Nothing     -- defaults to "https://api.openai.com/v1"
            }
    in
    OpenAI.Edits.createEdits
        { model = OpenAI.ModelID.TextDavinciEdit001
        , input = userInput
        , instruction = "Fix the spelling mistakes"
        , n = Nothing
        , temperature = Nothing
        , top_p = Nothing
        }
        |> OpenAI.withConfig cfg
        |> Http.task
        |> Task.map .choices
```

### Implementation Notes

Functions like [`OpenAI.Edits.createEdits`](OpenAI-Edits#createEdits) does not return a `Task` because `Task` is an opaque value and could be composed of a chain of http requests; if this package is compromised, your credentials could be sent to somewhere unexpected. Instead, "task functions" in this library returns a `Ext.Http.TaskInput`, ready to be passed to `Http.task`.

The error type in this package is [`Ext.Http.Error a`](https://package.elm-lang.org/packages/choonkeat/elm-ext-http/latest/Ext-Http). See the documentation for more details on why not [`Http.Error`](https://package.elm-lang.org/packages/elm/http/latest/Http#Error).