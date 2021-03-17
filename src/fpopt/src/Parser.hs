{-# LANGUAGE FlexibleContexts #-}

module Parser
    ( run_parser
    , parser
    ) where

import Lexer

import Data.Functor.Identity
import Text.Parsec
import Text.Parsec.String
import Text.Parsec.Expr hiding (Operator)

-- A TMatlab (Typed Matlab) program consists of
-- a list of statements separated by semicolons or newlines
-- If the semicolon is missing from the statement, the result of
-- the expression is printed in the "OUTPUT" section of the Satire DSL
-- Statements consist only of the form V = E; where V is a variable
-- and E is an expression or initialization statement
type TMatlab = [Command]
data Command =
      Statement Variable Expression Print
    | Pragma Variable Precision Dims
    deriving Show
data Precision = MSingle | MDouble
    deriving (Show, Eq)
data Print = Output | Silent
    deriving (Show, Eq)
type Dims = (Integer, Integer)
type Variable = String

data Expression =
      Initialize Initializer Dims -- zeros(n,m) or ones(n,1) or eye(n,n)
    | UnaryOp  Operator Expression
    | BinaryOp Operator Expression Expression
    | Variable String
    | Scalar   Double
    deriving Show
data Operator =
      Times      -- A*B, matrix-matrix or matrix-vector product
    | Minus      -- A-B, elementwise subtraction
    | Plus       -- A+B, elementwise addition
    | Divide     -- A/b, elementwise division
    | Transpose  -- A', transpose of matrix or vector
    deriving Show
data Initializer = Zeros | Ones | Eye | Rand
instance Show Initializer where
    show Zeros = "zeros"
    show Ones = "ones"
    show Eye = "eye"
    show Rand = "rand"

expr_parser :: Parser Expression
expr_parser = buildExpressionParser expr_table term <?> "expression"
expr_table = [
    [postfix  "'"  (UnaryOp Transpose)],
    [
        binary "*"  (BinaryOp Times) AssocLeft,
        binary "/" (BinaryOp Divide) AssocLeft
    ],
    [
        binary "+"  (BinaryOp Plus)  AssocLeft,
        binary "-"  (BinaryOp Minus) AssocLeft
    ] ]

initializer :: Parser Initializer
initializer =
        (reserved "zeros" >> return Zeros)
    <|> (reserved "ones" >> return Ones)
    <|> (reserved "eye" >> return Eye)
    <|> (reserved "rand" >> return Rand)
    <?> "zeros, ones, eye, rand as initializer"

precision :: Parser Precision
precision =
        (reserved "float" >> return MSingle)
    <|> (reserved "double" >> return MDouble)
    <?> "expected 'float' or 'double' precision"

dims :: Parser Dims
dims = do
    args <- parens $ commaSep $ natural
    case length args of
        1 -> return ((args !! 0), (args !! 0))
        2 -> return ((args !! 0), (args !! 1))
        _ -> error "shape should be (N) for NxN or (M,N) for MxN"

term :: Parser Expression
term = parens expr_parser
    <|> do
        i <- initializer
        shape <- dims
        return $ Initialize i shape
    <|> fmap Scalar float
    <|> fmap Variable identifier
    <?> "variable, initializer, or numeric scalar"
binary op fun assoc = Infix (do { reservedOp op; return fun }) assoc
postfix op fun = Postfix (do { reservedOp op; return fun })

command :: Parser Command
command =
    try statement <|> pragma
    <?> "expecting statement or type information"

pragma :: Parser Command
pragma = do
    v <- identifier
    reservedOp "::"
    p <- precision
    shape <- dims
    return $ Pragma v p shape
    
statement :: Parser Command
statement = do
    l <- identifier
    reservedOp "="
    e <- expr_parser
    print <- (semi >> return Silent) <|> (return Output)
    return $ Statement l e print

-- IDEA: Make a comment a "statement", inserting it in the outputted file to help
--       annotate it

parser :: Parser TMatlab
parser = whiteSpace *> many command <* eof

run_parser :: Stream s Identity t => Parsec s () p -> SourceName -> s -> p
run_parser p fn st = case parse p fn st of
    Left error_string -> error ("parse error: " ++ show error_string)
    Right parsed -> parsed

