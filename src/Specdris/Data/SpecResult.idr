module Specdris.Data.SpecResult

import Specdris.Data.ConsoleColor
import Specdris.Data.SpecState

%access export
%default total

||| Result of a single `Expectation`s or `Pending` if none
||| exists.
public export
data SpecResult : Type where     
     Pending : (message : Maybe String) -> SpecResult
     
     Success : SpecResult
     
     UnaryFailure : Show a => (val : a) -> (reason : String) -> SpecResult
     BinaryFailure : (Show a, Show b) => (left : a) -> (right : b) -> (reason : String) -> SpecResult

Eq SpecResult where
  (==) (Pending aMsg) (Pending bMsg)                           = aMsg == bMsg
  (==) Success Success                                         = True
  (==) (UnaryFailure _ aReason) (UnaryFailure _ bReason)       = aReason == bReason
  (==) (BinaryFailure _ _ aReason) (BinaryFailure _ _ bReason) = aReason == bReason
  (==) _ _ = False

namespace SpecResultDo
  (>>=) : SpecResult -> (SpecResult -> SpecResult) -> SpecResult
  (>>=) (UnaryFailure actual reason) _           = (UnaryFailure actual reason)
  (>>=) (BinaryFailure actual expected reason) _ = (BinaryFailure actual expected reason)
  (>>=) result f                                 = f result

{- Evaluates a given expectation result in updates the `SpecState` accordingly:
     - `Success` : increase spec count
     - `Failure` : increase spec and failure count
     - `Pending` : encrease spec and pending count
   Furthermore it prints the result to console.
 -}
evalResult : SpecResult -> SpecState -> (level : Nat) -> IO SpecState
evalResult (Pending msg) state level = let output = case msg of
                                                      (Just msg) => format (" [] pending: " ++ msg) Yellow (level + 1)
                                                      Nothing    => format " [] pending" Yellow (level + 1) in
                                           
                                           do putStrLn output
                                              pure (addPending state)

evalResult Success state _ = pure $ addSpec state
evalResult (UnaryFailure a reason) state level    = do putStrLn (format (" [x] " ++ show a ++ " " ++ reason) Red (level + 1))
                                                       pure (addFailure state)
                                                                
evalResult (BinaryFailure a b reason) state level = do putStrLn (format (" [x] " ++ show a ++ " " ++ reason ++ " " ++ show b) Red (level + 1))
                                                       pure (addFailure state)
