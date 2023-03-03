module Client exposing (..)

import Ext.Http
import File
import Html exposing (Html, button, div, form, h2, hr, input, pre, text)
import Html.Attributes exposing (accept, multiple, type_, value)
import Html.Events exposing (on, onClick, onInput, onSubmit)
import Http
import Json.Decode
import OpenAI
import OpenAI.Audio
import OpenAI.Common
import OpenAI.File
import Platform exposing (Task)
import Protocol
import Protocol.Auto
import RemoteData
import Task
import Webapp.Client



-- port websocketConnected : (Int -> msg) -> Sub msg
--
--
-- port websocketIn : (String -> msg) -> Sub msg
--
--
-- port websocketOut : String -> Cmd msg


webapp :
    { element : Webapp.Client.Program Flags Model Msg
    , sendToServer : Protocol.MsgFromClient -> Task Http.Error (Result String Protocol.MsgFromServer)
    }
webapp =
    Webapp.Client.element
        { element =
            { init = init
            , view = view
            , update = update
            , subscriptions = subscriptions
            }
        , ports =
            { websocketConnected = \_ -> Sub.none -- websocketConnected
            , websocketIn = \_ -> Sub.none -- websocketIn
            }
        , protocol =
            { updateFromServer = updateFromServer
            , clientMsgEncoder = Protocol.Auto.encodeProtocolMsgFromClient
            , serverMsgDecoder =
                Json.Decode.oneOf
                    [ Protocol.Auto.decodeProtocolMsgFromServer
                    , Json.Decode.map Protocol.ClientServerVersionMismatch Json.Decode.value
                    ]
            , errorDecoder = Json.Decode.string
            , httpEndpoint = Protocol.httpEndpoint
            }
        }


main : Webapp.Client.Program Flags Model Msg
main =
    webapp.element


{-| Clients send messages to Server with this
-}
sendToServer : Protocol.MsgFromClient -> Cmd Msg
sendToServer =
    webapp.sendToServer >> Task.attempt OnMsgFromServer


type alias Flags =
    { -- yikes don't do this in production
      --
      -- we are doing it here because we cannot use elm/http
      -- to send multipart form data from elm on nodejs
      -- used only for `OpenAI.Audio.createTranscription`
      openaiConfig : OpenAI.Config
    }


type alias Model =
    { greeting : String
    , serverGreeting : RemoteData.WebData String
    , openaiConfig : OpenAI.Config
    , openaiFiles : RemoteData.WebData (List OpenAI.Common.File)
    }


type Msg
    = OnMsgFromServer (Result Http.Error (Result String Protocol.MsgFromServer))
    | SendMessage Protocol.MsgFromClient
    | SetGreeting String
    | GotTranscriptionFiles (List File.File)
    | GotOpenAIFiles (List File.File)
    | ProcessedFiles (Result String (List String))
    | DeleteFile String


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { greeting = "What is a good programming language?"
      , serverGreeting = RemoteData.NotAsked
      , openaiConfig = flags.openaiConfig
      , openaiFiles = RemoteData.Loading
      }
    , sendToServer Protocol.GetOpenAIFiles
    )


view : Model -> Html.Html Msg
view model =
    div []
        [ h2 [] [ text "Files stored in OpenAI" ]
        , input
            [ type_ "file"
            , multiple True
            , on "change" (Json.Decode.map GotOpenAIFiles filesDecoder)
            ]
            []
        , pre [] [ text (Debug.toString model.openaiFiles) ]
        , div [] (List.map viewOpenAIFile (RemoteData.toMaybe model.openaiFiles |> Maybe.withDefault []))
        , form [ onSubmit (SendMessage (Protocol.SetGreeting model.greeting)) ]
            [ h2 [] [ text "Ask ChatGPT" ]
            , input [ onInput SetGreeting, value model.greeting ] []
            , button [ type_ "submit" ] [ text "Ask" ]
            ]
        , h2 [] [ text "Or, choose a mp3, mp4, mpeg, mpga, m4a, wav, or webm file to transcribe" ]
        , input
            [ type_ "file"
            , multiple True
            , accept ".mp3,.mp4,.mpeg,.mpga,.m4a,.wav,.webm"
            , on "change" (Json.Decode.map GotTranscriptionFiles filesDecoder)
            ]
            []
        , hr [] []
        , model.serverGreeting
            |> RemoteData.map (\str -> pre [] [ text str ])
            |> RemoteData.withDefault (pre [] [ text (Debug.toString model.serverGreeting) ])
        ]


viewOpenAIFile : OpenAI.Common.File -> Html.Html Msg
viewOpenAIFile file =
    button [ onClick (DeleteFile file.id) ]
        [ text ("Delete file=" ++ file.filename ++ ", id=" ++ file.id) ]


filesDecoder : Json.Decode.Decoder (List File.File)
filesDecoder =
    Json.Decode.at [ "target", "files" ] (Json.Decode.list File.decoder)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnMsgFromServer (Err err) ->
            -- http error
            ( { model | serverGreeting = RemoteData.succeed (Debug.toString err) }, Cmd.none )

        OnMsgFromServer (Ok (Err err)) ->
            -- error from Server.elm
            ( { model | serverGreeting = RemoteData.succeed ("app error: " ++ err) }, Cmd.none )

        OnMsgFromServer (Ok (Ok serverMsg)) ->
            updateFromServer serverMsg model

        SendMessage clientMsg ->
            ( { model | serverGreeting = RemoteData.Loading }, sendToServer clientMsg )

        SetGreeting s ->
            ( { model | greeting = s }, Cmd.none )

        GotTranscriptionFiles files ->
            ( { model | serverGreeting = RemoteData.Loading }
            , files
                |> List.map
                    (\file ->
                        OpenAI.Audio.createTranscription
                            { file = file
                            , model = OpenAI.Audio.Whisper_1
                            , prompt = Nothing
                            , response_format = Nothing
                            , temperature = Nothing
                            , language = Nothing
                            }
                            |> OpenAI.withConfig model.openaiConfig
                            |> Http.task
                            |> Task.mapError Ext.Http.errorString
                            |> Task.map Debug.toString
                    )
                |> Task.sequence
                |> Task.attempt ProcessedFiles
            )

        GotOpenAIFiles files ->
            ( { model | serverGreeting = RemoteData.Loading }
            , files
                |> List.map
                    (\file ->
                        OpenAI.File.uploadFile
                            (OpenAI.File.FilePurposeGeneral "fine-tune" file)
                            |> OpenAI.withConfig model.openaiConfig
                            |> Http.task
                    )
                |> Task.sequence
                |> Task.onError (\_ -> Task.succeed [])
                |> Task.andThen (\_ -> webapp.sendToServer Protocol.GetOpenAIFiles)
                |> Task.attempt OnMsgFromServer
            )

        ProcessedFiles result ->
            ( { model | serverGreeting = RemoteData.succeed (Debug.toString result) }
            , Cmd.none
            )

        DeleteFile id ->
            ( { model | openaiFiles = RemoteData.Loading }
            , sendToServer (Protocol.DeleteFileById id)
            )


updateFromServer : Protocol.MsgFromServer -> Model -> ( Model, Cmd Msg )
updateFromServer serverMsg model =
    case serverMsg of
        Protocol.ManyMsgFromServer msglist ->
            -- Handling a batched list of `MsgFromServer`
            let
                overModelAndCmd nextMsg ( currentModel, currentCmd ) =
                    updateFromServer nextMsg currentModel
                        |> Tuple.mapSecond (\nextCmd -> Cmd.batch [ nextCmd, currentCmd ])
            in
            List.foldl overModelAndCmd ( model, Cmd.none ) msglist

        Protocol.ClientServerVersionMismatch raw ->
            ( { model | serverGreeting = RemoteData.succeed "Oops! This page has expired. Please reload this page in your browser." }
            , Cmd.none
            )

        Protocol.CurrentGreeting s ->
            ( { model | serverGreeting = RemoteData.succeed s }, Cmd.none )

        Protocol.GotOpenAIFiles files ->
            ( { model | openaiFiles = RemoteData.Success files }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
