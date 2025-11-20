module Simplytyped
  ( conversion
  ,    -- conversion a terminos localmente sin nombre
    eval
  ,          -- evaluador
    infer
  ,         -- inferidor de tipos
    quote          -- valores -> terminos
  )
where

import           Data.List
import           Data.Maybe
import           Prelude                 hiding ( (>>=) )
import           Text.PrettyPrint.HughesPJ      ( render )
import           PrettyPrinter
import           Common

-----------------------
-- conversion
-----------------------
-- data Type = EmptyT | FunT Type Type
-- data LamTerm = LVar String | LAbs String Type LamTerm | LApp LamTerm LamTerm
-- data Term = Bound Int | Free Name | Term :@: Term | Lam Type Term

-- conversion a términos localmente sin nombres
conversion :: LamTerm -> Term
conversion lt = conv lt []

conv :: LamTerm -> [(String, Int)] -> Term
conv (LVar v) st       = case search v st of
                           Nothing -> Free (Global v)
                           Just x  -> Bound x
conv (LAbs v t lt) st  = Lam t (conv lt (addVar v (plus1 st)))
conv (LApp lt1 lt2) st = (conv lt1 st) :@: (conv lt2 st)
conv (LLet v t1 t2) st = Let (conv t1 st) (conv t2 (addVar v (plus1 st)))

search s [] = Nothing
search s ((s',i):xs) = if (s == s') then Just i else search s xs

addVar :: String -> [(String, Int)] -> [(String, Int)]
addVar v []     = [(v, 0)]
addVar v (x:xs) | v == (fst x) = (v, 0):xs
                | otherwise    = x:(addVar v xs)

plus1 xs = map (\(s,i) -> (s,i+1)) xs



----------------------------
--- evaluador de términos
----------------------------

-- substituye una variable por un término en otro término
sub :: Int -> Term -> Term -> Term
sub i t (Bound j) | i == j    = t
sub _ _ (Bound j) | otherwise = Bound j
sub _ _ (Free n   )           = Free n
sub i t (u   :@: v)           = sub i t u :@: sub i t v
sub i t (Lam t'  u)           = Lam t' (sub (i + 1) t u)
sub i t (Let t1 t2)           = Let (sub (i+1) t t1) (sub (i+1) t t2) -- Let t1 (sub (i+1) t t2)

-- convierte un valor en el término equivalente
quote :: Value -> Term
quote (VLam t f) = Lam t f

-- evalúa un término en un entorno dado
-- type NameEnv v t = [(Name, (v, t))]

eval :: NameEnv Value Type -> Term -> Value

eval nvs (Lam t term) = VLam t term
eval nvs (Free name) =
  case lookup name nvs of
    Just (v, _) -> v
    Nothing     -> error ("Variable libre no encontrada: " ++ show name)
eval nvs (t1 :@: t2) =
  case eval nvs t1 of
    VLam _ body ->
      let v2 = eval nvs t2
       in eval nvs (sub 0 (quote v2) body)
    v1 -> case eval nvs t2 of
            v2 -> error ("No se puede aplicar el valor " ++ show v1 ++ " a " ++ show v2)
eval nvs (Let t1 t2) = eval nvs (sub 0 t1 t2)

----------------------
--- type checker
-----------------------

-- infiere el tipo de un término
infer :: NameEnv Value Type -> Term -> Either String Type
infer = infer' []

-- definiciones auxiliares
ret :: Type -> Either String Type
ret = Right

err :: String -> Either String Type
err = Left

(>>=)
  :: Either String Type -> (Type -> Either String Type) -> Either String Type
(>>=) v f = either Left f v
-- fcs. de error

matchError :: Type -> Type -> Either String Type
matchError t1 t2 =
  err
    $  "se esperaba "
    ++ render (printType t1)
    ++ ", pero "
    ++ render (printType t2)
    ++ " fue inferido."

notfunError :: Type -> Either String Type
notfunError t1 = err $ render (printType t1) ++ " no puede ser aplicado."

notfoundError :: Name -> Either String Type
notfoundError n = err $ show n ++ " no está definida."

-- infiere el tipo de un término a partir de un entorno local de variables y un entorno global
infer' :: Context -> NameEnv Value Type -> Term -> Either String Type
infer' c _ (Bound i) = ret (c !! i)
infer' _ e (Free  n) = case lookup n e of
  Nothing     -> notfoundError n
  Just (_, t) -> ret t
infer' c e (t :@: u) = infer' c e t >>= \tt -> infer' c e u >>= \tu ->
  case tt of
    FunT t1 t2 -> if (tu == t1) then ret t2 else matchError t1 tu
    _          -> notfunError tt
infer' c e (Lam t u) = infer' (t : c) e u >>= \tu -> ret $ FunT t tu

