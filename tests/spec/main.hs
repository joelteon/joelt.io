module Main where

import Test.Hspec.Runner
import Test.Hspec.Formatters
import qualified Spec
import Prelude

main :: IO ()
main = hspecWith defaultConfig { configFormatter = Just progress } Spec.spec
