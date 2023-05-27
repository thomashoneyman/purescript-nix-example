module App.Main where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Lib as Lib
import Registry.Constants as Registry.Constants

main :: Effect Unit
main = log $ Lib.pizza <> " " <> Registry.Constants.apiUrl
