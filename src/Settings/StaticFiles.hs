{-# LANGUAGE OverloadedLists #-}

module Settings.StaticFiles where

import qualified Data.ByteString.Lazy.Char8 as B8
import Data.Default (def)
import qualified Data.Text.Lazy.Encoding as LT
import Filesystem.Path
import Data.String
import Language.Haskell.TH (Q, Exp, Name)
import Prelude hiding (FilePath)
import Settings (appStaticDir, compileTimeAppSettings)
import System.Exit
import System.Process.ByteString.Lazy (readProcessWithExitCode)
import Text.Lucius (luciusRTMinified)
import Text.Printf (printf)
import Yesod.Static.Extended

staticFiles (appStaticDir compileTimeAppSettings)

staticFilesList "bower_components/bootstrap/dist"
    [ "js/bootstrap.js"
    , "css/bootstrap.css"
    ]

staticFilesList "bower_components/tipsy/src"
    [ "javascripts/jquery.tipsy.js"
    , "stylesheets/tipsy.css"
    , "images/tipsy.gif"
    ]

combineSettings :: CombineSettings
combineSettings = def
    { csStaticDirs = [ fromString (appStaticDir compileTimeAppSettings)
                     , "bower_components/bootstrap/dist"
                     , "bower_components/tipsy/src" ]
    , csCssPostProcess = \fps ->
          either (error . errorIntro fps) (return . LT.encodeUtf8)
        . flip luciusRTMinified []
        . LT.decodeUtf8
    , csJsPostProcess = uglify
    }
    where
        errorIntro fps s = "Error minifying " ++ show fps ++ ": " ++ s

uglify :: [FilePath] -> B8.ByteString -> IO B8.ByteString
uglify paths code = do
    (status, out, err) <- readProcessWithExitCode "uglifyjs" ["-c", "-m"] code
    case status of
        ExitSuccess -> return out
        ExitFailure i -> error $ printf "Error minifying %s (shell exited %d): %s"
            (show paths) i (B8.unpack err)

combineStylesheets :: Name -> [Route Static] -> Q Exp
combineStylesheets = combineStylesheets' False combineSettings

combineScripts :: Name -> [Route Static] -> Q Exp
combineScripts = combineScripts' False combineSettings
