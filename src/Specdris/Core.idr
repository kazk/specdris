module Specdris.Core

import Specdris.Data.SpecInfo
import Specdris.Data.SpecResult
import Specdris.Data.SpecState

%access export
%default total

||| BTree with elements in the leafs.
public export
data Tree : Type -> Type where
     Leaf : (elem : a) -> Tree a
     Node : (left : Tree a) -> (right : Tree a) -> Tree a

public export
SpecTree' : FFI -> Type
SpecTree' ffi = Tree (Either SpecInfo (IO' ffi SpecResult))

public export
SpecTree : Type
SpecTree = SpecTree' FFI_C


namespace SpecTreeDo
  (>>=) : SpecTree' ffi -> (() -> SpecTree' ffi) -> SpecTree' ffi
  (>>=) leftTree f = let rightTree = f () in
                         Node leftTree rightTree

{- Evaluates every leaf in the `SpecTree` and folds the different `IO`s to collect
   a final `SpecState`.
   
   Test:
     describe "a" $ do
       describe "b" $ do
         it "c" test_io_c
       it "d" test_io_d
   
   Tree from Test:
                        Node
                         |
         ----------------------------------
         |                                |
    Leaf Desc "a"                        Node
                                          |
                                 ---------------------         
                                 |                   |
                                Node                Node
                                 |                   |
                       -------------               --------------- 
                       |           |               |             |
                 Leaf Desc "b"    Node        Leaf It "d"  Leaf test_io_d
                                   |
                            ----------------
                            |              |
                       Leaf It "c"   Leaf test_io_c
 -}
evaluateTree : SpecTree' ffi ->
               SpecState -> 
               (around : IO' ffi SpecResult -> IO' ffi SpecResult) ->
               (storeOutput : Bool) -> 
               (level : Nat) -> 
               IO' ffi SpecState
-- description or it
evaluateTree (Leaf (Left info)) state _ store level         = let out = evalInfo info level in
                                                                  if store then
                                                                    pure $ addLine out state
                                                                  else do 
                                                                    putStrLn' out
                                                                    pure state

-- test case
evaluateTree (Leaf (Right specIO)) state around store level = evalResult !(around specIO) state store level

-- recursive step
evaluateTree (Node left right) state around store level 
  = case left of
        -- node containing a description/it -> new level of output indentation
        (Leaf _) => do newState <- evaluateTree left state around store (level + 1)
                       tmpState <- evaluateTree right newState around store (level + 1)
                       if store then
                         pure $ addLine "\n<COMPLETEDIN::>" tmpState
                       else do
                         putStrLn' "\n<COMPLETEDIN::>"
                         pure tmpState
                       
        _        => do newState <- evaluateTree left state around store level
                       evaluateTree right newState around store level

evaluate : (around : IO' ffi SpecResult -> IO' ffi SpecResult) -> (storeOutput : Bool) -> SpecTree' ffi -> IO' ffi SpecState
evaluate around store tree = evaluateTree tree neutral around store 0

randomBase : Integer
randomBase = pow 2 32

randomInt : (seed : Integer) -> Integer
randomInt seed = assert_total ((1664525 * seed + 1013904223) `prim__sremBigInt` randomBase)

randomDouble : (seed : Integer) -> Double
randomDouble seed = let value = randomInt seed in
                      (cast {to = Double} value) / (cast {to = Double} randomBase)

partial
shuffle : {default randomDouble rand : Integer -> Double} -> SpecTree' ffi -> (seed : Integer) -> SpecTree' ffi
shuffle {rand} (Node left@(Leaf _) right@(Leaf _)) seed          = Node left right
shuffle {rand} (Node left@(Leaf (Left (Describe _))) right) seed = Node left (shuffle {rand = rand} right seed)
shuffle {rand} (Node left@(Node _ _) right@(Node _ _)) seed      = let randVal  = rand seed 
                                                                       nextSeed = (cast {to = Integer} randVal) * 100 in
                                                                     if randVal > 0.5 then 
                                                                       Node (shuffle {rand = rand} left nextSeed) (shuffle {rand = rand} right nextSeed)
                                                                     else
                                                                       Node (shuffle {rand = rand} right nextSeed) (shuffle {rand = rand} left nextSeed)
