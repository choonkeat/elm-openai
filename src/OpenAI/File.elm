module OpenAI.File exposing
    ( uploadFile, getFile, getFileContent, getFiles, deleteFile
    , UploadInput(..), PromptCompletion
    )

{-|

> Files are used to upload documents that can be used with features like Fine-tuning.

See <https://beta.openai.com/docs/api-reference/files>

@docs uploadFile, getFile, getFileContent, getFiles, deleteFile

@docs UploadInput, PromptCompletion

-}

import Bytes exposing (Bytes)
import Dict
import Ext.Http
import Http
import Json.Decode
import Json.Encode
import OpenAI.Common
import OpenAI.Internal


{-| <https://beta.openai.com/docs/api-reference/files/list>
-}
getFiles : Ext.Http.TaskInput (Ext.Http.Error String) (List OpenAI.Common.File)
getFiles =
    { method = "GET"
    , headers = []
    , url = "/files"
    , body = Http.emptyBody
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver (Json.Decode.list OpenAI.Internal.decodeFile) >> Result.map .data)
    , timeout = Nothing
    }


{-| -}
type alias PromptCompletion =
    { prompt : String, completion : String }


encodePromptCompletion : PromptCompletion -> Json.Encode.Value
encodePromptCompletion input =
    Json.Encode.object
        [ ( "prompt", Json.Encode.string input.prompt )
        , ( "completion", Json.Encode.string input.completion )
        ]


{-| -}
type UploadInput
    = FilePurposeFineTune (List PromptCompletion)
    | FilePurposeGeneral String OpenAI.Common.BinaryBlob


formEncodeUploadInput : UploadInput -> List Http.Part
formEncodeUploadInput input =
    case input of
        FilePurposeFineTune promptCompletions ->
            [ Http.stringPart "purpose" "fine-tune"
            , Http.stringPart "prompt"
                (Json.Encode.encode 0 (Json.Encode.list encodePromptCompletion promptCompletions))
            ]

        FilePurposeGeneral purpose blob ->
            [ Http.stringPart "purpose" purpose
            , Http.bytesPart "file" blob.contentType blob.bytes
            ]


{-| <https://beta.openai.com/docs/api-reference/files/upload>
-}
uploadFile : UploadInput -> Ext.Http.TaskInput (Ext.Http.Error String) OpenAI.Common.File
uploadFile input =
    { method = "POST"
    , headers = []
    , url = "/files"
    , body = Http.multipartBody (formEncodeUploadInput input)
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver OpenAI.Internal.decodeFile >> Result.map .data)
    , timeout = Nothing
    }


{-| <https://beta.openai.com/docs/api-reference/files/delete>
-}
deleteFile : { file_id : String } -> Ext.Http.TaskInput (Ext.Http.Error String) OpenAI.Common.DeleteOutput
deleteFile input =
    { method = "DELETE"
    , headers = []
    , url = "/files/" ++ input.file_id
    , body = Http.emptyBody
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver OpenAI.Internal.decodeDeleteOutput >> Result.map .data)
    , timeout = Nothing
    }


{-| <https://beta.openai.com/docs/api-reference/files/retrieve>
-}
getFile : { file_id : String } -> Ext.Http.TaskInput (Ext.Http.Error String) OpenAI.Common.File
getFile input =
    { method = "GET"
    , headers = []
    , url = "/files/" ++ input.file_id
    , body = Http.emptyBody
    , resolver =
        Http.stringResolver
            (Ext.Http.jsonResolver OpenAI.Internal.decodeFile >> Result.map .data)
    , timeout = Nothing
    }


{-| <https://beta.openai.com/docs/api-reference/files/retrieve-content>
-}
getFileContent : { file_id : String } -> Ext.Http.TaskInput (Ext.Http.Error Bytes) OpenAI.Common.BinaryBlob
getFileContent input =
    { method = "GET"
    , headers = []
    , url = "/files/" ++ input.file_id ++ "/content"
    , body = Http.emptyBody
    , resolver =
        Http.bytesResolver
            (Ext.Http.identityResolver
                >> Result.map
                    (\{ meta, data } ->
                        { contentType =
                            Dict.get "content-type" meta.headers
                                |> Maybe.withDefault "application/octet-stream"
                        , bytes = data
                        }
                    )
            )
    , timeout = Nothing
    }
