module Main where

import           Parser
import           System.Environment

usage = "usage: stack exec fpopt <filename>"

main :: IO ()
main = do
    args <- getArgs
    case length args of
        1 -> parseMain (head args)
        _ -> putStrLn usage

-- parsing has the effect of printing the parse tree as a string
-- and writing the translated file to out.c, and a Makefile
parseMain :: String -> IO ()
parseMain filename = do
    putStrLn ("# Generated from " ++ filename)
    s <- readFile filename
    let m = run_parser parser filename s
    putStrLn $ "# " ++ (show m)

