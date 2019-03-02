module Specdris.OutputTest

import Specdris.Spec
import Specdris.TestUtil

expected : List String
expected = ["\n<DESCRIBE::>context 1",
            "\n<DESCRIBE::>context 1.1",
            "\n<IT::>context 1.1.1",
            "\n<FAILED::>not equal<:LF:>    actual:   1<:LF:>    expected: 2",
            "\n<COMPLETEDIN::>",
            "\n<COMPLETEDIN::>",
            "\n<IT::>context 1.2",
            "\n<FAILED::>not equal<:LF:>    actual:   1<:LF:>    expected: 2",
            "\n<COMPLETEDIN::>",
            "\n<IT::>context 1.3",
            "\n<LOG::>pending: for some reason",
            "\n<COMPLETEDIN::>",
            "\n<COMPLETEDIN::>"]

testCase : IO ()
testCase
  = do state <- specWithState {storeOutput = True} $ do
             describe "context 1" $ do
               describe "context 1.1" $ do
                 it "context 1.1.1" $ do
                   1 === 2        
               it "context 1.2" $ do
                 1 `shouldBe` 2
               it "context 1.3" $ do
                 pendingWith "for some reason"
       
       testAndPrint "spec output" (output state) (Just expected) (==)

export
specSuite : IO ()
specSuite = do putStrLn "\n  output:"
               testCase
