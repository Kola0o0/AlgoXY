{-
    BTree.hs, B-Tree in Haskell.
    Copyright (C) 2010, Liu Xinyu (liuxinyu95@gmail.com)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
-}

module Main where

import System.Environment (getArgs)
import Text.ParserCombinators.Parsec
import Control.Monad (mapM_)
import Data.List (intercalate, zipWith)
import System.IO (writeFile)

--auxiliar parser functions

-- input: a1, b1, a2, b2, ... an, bn, a{n+1}
-- output: ([a1, a2, ..., an, a{n+1}], [b1, b2, ..., bn])
everyOther pa pb sep = do{ x <- pa
                         ; sep
                         ; (ys, xs)<- every2 pb pa sep
                         ; return (x:xs, ys)}
-- input a1, b1, a2, b2, ... an, bn
-- output: ([a1, ..., an], [b1, ..., bn])
every2 pa pb sep = scan where
    scan = do { x<-pa
              ; y<-(sep>>pb)
              ; do {
                ; (xs, ys)<-(sep>>scan)
                ; return (x:xs, y:ys)
                }
              <|> return ([x], [y])
              }

-- we needn't min-degree for B-Tree node definition here
data Node a = Node [a] [Node a] deriving (Eq, Show)

node = (try leaf) <|> branch

leaf = do
  char '('
  ks <- key `sepBy` (string "," >> spaces)
  char ')'
  return (Node ks [])

branch = do 
  char '('
  (cs, ks)<- everyOther node key (string ", ")
  char ')'
  return (Node ks cs)

key = many (noneOf ", ()")

parseArgs :: [String] -> (String, String)
parseArgs [fname, s] = (fname, s)
parseArgs _ = error "wrong usage\nexample:\nbt2dot output.dot \"((B, C), A, (D, E))\""

toDot (Node ks []) prefix = prefix++(concat ks)++"[label=\""++(intercalate "|" ks)++"\"];\n"
toDot (Node ks cs) prefix = prefix'++"[label=\""++(defNode ks)++"\"];\n" ++
                            (concat $ map (\c->toDot c prefix') cs) ++
                            (defCons cs prefix')
                                where prefix' = prefix ++ (concat ks)

defNode :: [String] -> String
defNode ks = "<C0>"++ (concat $ zipWith (\i k->"|"++k++"|<C"++(show i)++">")  [1..] ks)

defCons cs prefix = concat $ zipWith f [0..] cs where
    f i c = prefix++":C"++(show i)++"->"++prefix++(nodeName c)++";\n"
    nodeName (Node ks _) = concat ks

genDot fname (Right node) = writeFile fname dots >> putStrLn dots
    where
      dots = "digraph G{\n\tnode[shape=record]\n"++(addTab $ toDot node "t")++"}"
      addTab s = unlines $ map ("\t"++) (lines s)

-- tests
testParse = mapM_ (\x->putStrLn $ show $ (parse node "unknown" x))
            ["((A, B), C, (D, E))", 
             "((A,B), C, (D,E))", 
             "(((A, B), C, (D, E, F), G, (H, I, J, K)), M, ((N, O), P, (Q, R, S), T, (U, V), W, (X, Y, Z)))"]

testDefNode = map defNode [["A"], ["A", "B", "C"]]

testToDot = putStrLn $ toDot (Node ["C"] [Node ["A","B"] [],Node ["D","E"] []]) "t"

main = do
  args <- getArgs
  let (fname, s) = parseArgs args
  genDot fname (parse node "unknown" s)