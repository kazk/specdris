module Specdris.Data.SpecInfo

import Specdris.Data.ConsoleColor

%access export
%default total

||| Information/Specification about a certain module/data
||| and/or the description of its test cases.
public export
data SpecInfo : Type where
     Describe : (msg : String) -> SpecInfo
     It : (msg : String) -> SpecInfo

{- Evaluates the given `SpecInfo` by printing the formatted
   information to console.
 -}
evalInfo : SpecInfo -> (level : Nat) -> String
evalInfo (Describe msg) level = format ("\n<DESCRIBE::>" ++ msg) White level
evalInfo (It msg)       level = format ("\n<IT::>" ++ msg) White level
