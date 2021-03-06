-- | A @pretty@ implementation of a pretty-printer for 'Shower'.
module Shower.Printer (ShowerDoc(SD), showerRender) where

import Data.Coerce
import qualified Text.PrettyPrint as PP

import Shower.Class

-- | A @pretty@ document, with a 'Shower' instance.
newtype ShowerDoc = SD PP.Doc

instance Shower ShowerDoc where
  showerRecord = coerce showerRecord'
  showerList = coerce showerList'
  showerTuple = coerce showerTuple'
  showerStringLit = coerce showerStringLit'
  showerCharLit = coerce showerCharLit'
  showerSpace = coerce showerSpace'
  showerAtom = coerce showerAtom'

showerPunctuate :: (a -> PP.Doc) -> [ShowerComma a] -> [PP.Doc]
showerPunctuate showerElem = go
  where
    go [] = []
    go (ShowerCommaElement x : ShowerCommaSep : xs) =
      (showerElem x PP.<> PP.char ',') : go xs
    go (ShowerCommaElement x : xs) = showerElem x : go xs
    go (ShowerCommaSep : xs) = PP.char ',' : go xs

showerRecord' :: [ShowerComma (PP.Doc, ShowerFieldSep, PP.Doc)] -> PP.Doc
showerRecord' fields =
  PP.braces (PP.nest 2 (showerFields fields))
  where
    showerFields = PP.sep . showerPunctuate showerField
    showerField (name, sep, x) = PP.hang (ppSep name sep) 2 x
    ppSep name ShowerFieldSepEquals = name PP.<+> PP.char '='
    ppSep name ShowerFieldSepColon  = name PP.<>  PP.char ':'

showerList' :: [ShowerComma PP.Doc] -> PP.Doc
showerList' elements =
  PP.brackets (PP.nest 2 (showerElements elements))
  where
    showerElements = PP.sep . showerPunctuate id

showerTuple' :: [ShowerComma PP.Doc] -> PP.Doc
showerTuple' elements =
  PP.parens (PP.nest 2 (showerElements elements))
  where
    showerElements = PP.sep . showerPunctuate id

showerSpace' :: [PP.Doc] -> PP.Doc
showerSpace' (x:xs) = PP.hang x 2 (PP.sep xs)
showerSpace' xs = PP.sep xs

showerAtom' :: String -> PP.Doc
showerAtom' = PP.text

showerStringLit' :: String -> PP.Doc
showerStringLit' = PP.doubleQuotes . PP.text

showerCharLit' :: String -> PP.Doc
showerCharLit' = PP.quotes . PP.text

-- | Render a @ShowerDoc@ with the default style.
showerRender :: ShowerDoc -> String
showerRender (SD showerDoc) =
  PP.renderStyle PP.style{ PP.lineLength = 80 } showerDoc ++ "\n"
