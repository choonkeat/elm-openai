module OpenAI.Common exposing (BinaryBlob, DeleteOutput, File, Usage)

{-| Common types used in the OpenAI API.

@docs BinaryBlob, DeleteOutput, File, Usage

-}

import Bytes exposing (Bytes)
import Time


{-| <https://beta.openai.com/docs/api-reference/making-requests>
-}
type alias Usage =
    { prompt_tokens : Int
    , completion_tokens : Int
    , total_tokens : Int
    }


{-| <https://beta.openai.com/docs/api-reference/images/create-edit>
-}
type alias BinaryBlob =
    { contentType : String
    , bytes : Bytes
    }


{-| <https://beta.openai.com/docs/api-reference/files>
-}
type alias File =
    { id : String
    , object : String
    , bytes : Int
    , created_at : Time.Posix
    , filename : String
    , purpose : String
    }


{-| <https://beta.openai.com/docs/api-reference/files/delete>
-}
type alias DeleteOutput =
    { id : String
    , object : String
    , deleted : Bool
    }
