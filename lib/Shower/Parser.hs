module Shower.Parser (pShower) where

import Data.Void
import Data.Char
import Text.Megaparsec
import Text.Megaparsec.Char

import Shower.Class

type Parser = Parsec Void String

pLexeme :: Parser a -> Parser a
pLexeme p = p <* space

pShower :: Shower a => Parser a
pShower = space *> pExpr

pExpr :: Shower a => Parser a
pExpr = showerSpace <$> some pPart

pPart :: Shower a => Parser a
pPart =
  pRecord <|>
  pList <|>
  pTuple <|>
  pStringLit <|>
  pCharLit <|>
  pAtom

pRecord :: Shower a => Parser a
pRecord = do
  _ <- pLexeme (char '{')
  fields <- pField `sepBy` pLexeme (char ',')
  _ <- pLexeme (char '}')
  return (showerRecord fields)

pField :: Shower a => Parser (a, a)
pField = do
  name <- pExpr
  _ <- pLexeme (char '=')
  value <- pExpr
  return (name, value)

pList :: Shower a => Parser a
pList = do
  _ <- pLexeme (char '[')
  elements <- pExpr `sepBy` pLexeme (char ',')
  _ <- pLexeme (char ']')
  return (showerList elements)

pTuple :: Shower a => Parser a
pTuple = do
  _ <- pLexeme (char '(')
  elements <- pExpr `sepBy` pLexeme (char ',')
  _ <- pLexeme (char ')')
  return (showerTuple elements)

pQuotedLit :: Char -> Parser String
pQuotedLit quote =
  pLexeme $ do
    _ <- char quote
    s <- manyTill pSymbol (char quote)
    return (concat s)
  where
    pSymbol =
      string ['\\', '\\']  <|>
      string ['\\', quote] <|>
      ((:[]) <$> anySingle)

pStringLit :: Shower a => Parser a
pStringLit = showerStringLit <$> pQuotedLit '"'

pCharLit :: Shower a => Parser a
pCharLit = showerCharLit <$> pQuotedLit '\''

pAtom :: Shower a => Parser a
pAtom =
  pLexeme $ do
    s <- some (satisfy atomChar)
    return (showerAtom s)
  where
    atomChar c =
      not (c `elem` "()[]{},=") &&
      not (isSpace c)
