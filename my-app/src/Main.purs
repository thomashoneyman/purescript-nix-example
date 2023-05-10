module App.Main where

import Prelude

import Lib as Lib
import Effect (Effect)
import Effect.Console (log)

main :: Effect Unit
main = log Lib.pizza
