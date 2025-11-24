ack :: Int -> Int -> Int
ack 0 n = n + 1
ack m 0 = ack (m - 1) 1
ack m n = ack (m - 1) (ack m (n - 1))

-- def ack = 
--   \f:Nat -> Nat -> Nat. \m:Nat . \n:Nat . 
--   R (suc n) : Nat 
--     ( R 
--         (f (pred m) (suc 0)) 
--         (f (pred m) (f m (pred n)) )
--         n
--     )
--   m : Nat