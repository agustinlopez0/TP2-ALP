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
conv (LZero) st = Zero
conv (LSuc lt) st = Suc (conv lt st)
conv (LRec t1 t2 t3) st = Rec (conv t1 st) (conv t2 st) (conv t3 st)

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
sub i t (Let t1 t2)           = Let (sub i t t1) (sub (i+1) t t2)

-- convierte un valor en el término equivalente
quote :: Value -> Term
quote (VLam t f) = Lam t f

-- evalúa un término en un entorno dado
-- type NameEnv v t = [(Name, (v, t))]

eval :: NameEnv Value Type -> Term -> Value

eval env (Lam t term) = VLam t term
eval env (Free name) =
  case lookup name env of
    Just (v, _) -> v
    Nothing     -> error ("Variable libre no encontrada: " ++ show name)
eval env (t1 :@: t2) =
  case eval env t1 of
    VLam _ body ->
      let v2 = eval env t2
       in eval env (sub 0 (quote v2) body)
    v1 -> case eval env t2 of
            v2 -> error ("No se puede aplicar el valor " ++ show v1 ++ " a " ++ show v2)
eval env (Let t1 t2) =
  let v1 = eval env t1
  in eval env (sub 0 (quote v1) t2)
eval env Zero     = VNum NZero
eval env (Suc t)  =
  case eval env t of
    VNum n -> VNum (NSuc n)
    _      -> error "Suc solo se puede aplicar a un número"
eval env (Rec t1 t2 Zero) = eval env t1
eval env (Rec t1 t2 (Suc t)) = eval env (t2 :@: (Rec t1 t2 t) :@: t)
eval env (Rec t1 t2 t3) =
  let v3 = eval env t3
  in eval env (Rec t1 t2 (quote v3))

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

recTypeError :: Type -> Type -> Type -> Either String Type
recTypeError t1 t2 t3 =
  err $ "Error de tipos en Rec: " 
        ++ render (printType t1) ++ " (t1), "
        ++ render (printType t2) ++ " (t2), "
        ++ render (printType t3) ++ " (t3)"

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
infer' c e (Let t1 t2) =
  infer' c e t1 >>= \t1t -> infer' (t1t : c) e t2
infer' c e Zero = ret NatT
infer' c e (Suc t) = infer' c e t >>= \tt ->
                      if tt == NatT
                        then ret NatT
                        else notfunError tt
infer' c e (Rec t1 t2 t3) = infer' c e t1 >>= \tt 
                            -> infer' c e t2 >>= \tu 
                            -> infer' c e t3 >>= \tv 
                            ->
                                if (tu == (FunT (FunT tt NatT) tt)) && (tv == NatT)
                                  then ret tt
                                  else recTypeError tt tu tv
                                                      