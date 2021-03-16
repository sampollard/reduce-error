module Parser
    ( run_parser
    ) where

import Lexer -- We only use a few features of the Lexer
import Text.Parsec
import Text.Parsec.String
import Text.Parsec.Expr hiding (Operator)

run_parser :: Parser a -> String -> a
run_parser p str = case parse p "source name" str of
    Left error_string -> error ("parse error: " ++ show error_string)
    Right parsed -> parsed 

someFunc :: IO ()
someFunc = putStrLn "someFunc"
