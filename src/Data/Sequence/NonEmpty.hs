{-# LANGUAGE LambdaCase      #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ViewPatterns    #-}

module Data.Sequence.NonEmpty (
  -- * Finite sequences
    NESeq ((:<||), (:||>))
  -- ** Conversions between empty and non-empty sequences
  -- , pattern IsNonEmpty
  -- , pattern IsEmpty
  , nonEmptySeq
  , toSeq
  , withNonEmpty
  , unsafeFromSeq
  -- * Construction
  , singleton
  , (<|)
  , (|>)
  , (><)
  , fromList
  --   -- ** Repetition
  -- , replicate
  -- , replicateA
  -- , replicateM
  -- , cycleTaking
  -- ** Iterative construction
  , iterateN
  , unfoldr
  , unfoldl
  -- * Deconstruction
  -- | Additional functions for deconstructing sequences are available
  -- via the 'Foldable' instance of 'Seq'.

  -- ** Queries
  , length
  --   -- ** Views
  -- , ViewL(..)
  -- , viewl
  -- , ViewR(..)
  -- , viewr
  -- * Scans
  , scanl
  , scanl1
  , scanr
  , scanr1
  -- * Sublists
  , tails
  , inits
  , chunksOf
  -- ** Sequential searches
  -- , takeWhileL
  -- , takeWhileR
  -- , dropWhileL
  -- , dropWhileR
  -- , spanl
  -- , spanr
  -- , breakl
  -- , breakr
  -- , partition
  -- , filter
  --   -- * Sorting
  -- , sort
  -- , sortBy
  -- , sortOn
  -- , unstableSort
  -- , unstableSortBy
  -- , unstableSortOn
  --   -- * Indexing
  -- , lookup
  -- , (!?)
  -- , index
  -- , adjust
  -- , adjust'
  -- , update
  -- , take
  -- , drop
  -- , insertAt
  -- , deleteAt
  , splitAt
  -- ** Indexing with predicates
  -- | These functions perform sequential searches from the left
  -- or right ends of the sequence  returning indices of matching
  -- elements.
  -- , elemIndexL
  -- , elemIndicesL
  -- , elemIndexR
  -- , elemIndicesR
  -- , findIndexL
  -- , findIndicesL
  -- , findIndexR
  -- , findIndicesR
  --   -- * Folds
  --   -- | General folds are available via the 'Foldable' instance of 'Seq'.
  -- , foldMapWithIndex
  -- , foldlWithIndex
  -- , foldrWithIndex
  --   -- * Transformations
  -- , mapWithIndex
  -- , traverseWithIndex
  -- , reverse
  -- , intersperse
  -- ** Zips and unzip
  , zip
  , zipWith
  , zip3
  , zipWith3
  , zip4
  , zipWith4
  , unzip
  , unzipWith
  ) where

import           Data.Bifunctor
import           Data.List.NonEmpty (NonEmpty(..))
import           Data.Sequence      (Seq(..))
import           Data.These
import           Prelude hiding     (length, scanl, scanl1, scanr, scanr1, splitAt, zip, zipWith, zip3, zipWith3, unzip)
import qualified Data.Sequence      as Seq

data NESeq a = a :<|| !(Seq a)
  deriving Show

unsnoc :: NESeq a -> (Seq a, a)
unsnoc (x :<|| (xs :|> y)) = (x :<| xs, y)
unsnoc (x :<|| Empty     ) = (Empty   , x)
{-# INLINE unsnoc #-}

pattern (:||>) :: Seq a -> a -> NESeq a
pattern xs :||> x <- (unsnoc->(xs, x))
  where
    (x :<| xs) :||> y = x :<|| (xs :|> y)
    Empty      :||> y = y :<|| Empty
{-# COMPLETE (:||>) #-}

nonEmptySeq :: Seq a -> Maybe (NESeq a)
nonEmptySeq (x :<| xs) = Just $ x :<|| xs
nonEmptySeq Empty      = Nothing
{-# INLINE nonEmptySeq #-}

toSeq :: NESeq a -> Seq a
toSeq (x :<|| xs) = x :<| xs
{-# INLINE toSeq #-}

withNonEmpty :: r -> (NESeq a -> r) -> Seq a -> r
withNonEmpty def f = \case
    x :<| xs -> f (x :<|| xs)
    Empty    -> def
{-# INLINE withNonEmpty #-}

unsafeFromSeq :: Seq a -> NESeq a
unsafeFromSeq (x :<| xs) = x :<|| xs
unsafeFromSeq Empty      = errorWithoutStackTrace "NESeq.unsafeFromSeq: empty seq"
{-# INLINE unsafeFromSeq #-}

singleton :: a -> NESeq a
singleton = (:<|| Seq.empty)

(<|) :: a -> NESeq a -> NESeq a
x <| xs = x :<|| toSeq xs

(|>) :: NESeq a -> a -> NESeq a
(x :<|| xs) |> y = x :<|| (xs Seq.|> y)

(><) :: NESeq a -> NESeq a -> NESeq a
(x :<|| xs) >< ys = x :<|| (xs Seq.>< toSeq ys)

fromList :: NonEmpty a -> NESeq a
fromList (x :| xs) = x :<|| Seq.fromList xs

iterateN :: Int -> (a -> a) -> a -> NESeq a
iterateN n f x = x :<|| Seq.iterateN (n - 1) f (f x)

unfoldr :: (a -> (b, Maybe a)) -> a -> NESeq b
unfoldr f = go
  where
    go x0 = y :<|| maybe Seq.empty (toSeq . go) x1
      where
        (y, x1) = f x0
{-# INLINE unfoldr #-}

unfoldl :: (a -> (b, Maybe a)) -> a -> NESeq b
unfoldl f = go
  where
    go x0 = maybe Seq.empty (toSeq . go) x1 :||> y
      where
        (y, x1) = f x0
{-# INLINE unfoldl #-}

length :: NESeq a -> Int
length (_ :<|| xs) = 1 + Seq.length xs
{-# INLINE length #-}

scanl :: (a -> b -> a) -> a -> NESeq b -> NESeq a
scanl f y0 (x :<|| xs) = y0 :<|| Seq.scanl f (f y0 x) xs
{-# INLINE scanl #-}

scanl1 :: (a -> a -> a) -> NESeq a -> NESeq a
scanl1 f (x :<|| xs) = withNonEmpty (singleton x) (scanl f x) xs
{-# INLINE scanl1 #-}

scanr :: (a -> b -> b) -> b -> NESeq a -> NESeq b
scanr f y0 (xs :||> x) = Seq.scanr f (f x y0) xs :||> y0
{-# INLINE scanr #-}

scanr1 :: (a -> a -> a) -> NESeq a -> NESeq a
scanr1 f (xs :||> x) = withNonEmpty (singleton x) (scanr f x) xs
{-# INLINE scanr1 #-}

tails :: NESeq a -> NESeq (NESeq a)
tails xs@(_ :<|| ys) = withNonEmpty (singleton xs) ((xs <|) . tails) ys
{-# INLINABLE tails #-}

inits :: NESeq a -> NESeq (NESeq a)
inits xs@(ys :||> _) = withNonEmpty (singleton xs) ((|> xs) . inits) ys
{-# INLINABLE inits #-}

chunksOf :: Int -> NESeq a -> NESeq (NESeq a)
chunksOf n = go
  where
    go xs = case splitAt n xs of
      This  ys    -> singleton ys
      That     _  -> e
      These ys zs -> ys <| go zs
    e = error "chunksOf: A non-empty sequence can only be broken up into positively-sized chunks."
{-# INLINABLE chunksOf #-}

splitAt :: Int -> NESeq a -> These (NESeq a) (NESeq a)
splitAt 0 xs0             = That xs0
splitAt n xs0@(x :<|| xs) = case (nonEmptySeq ys, nonEmptySeq zs) of
    (Nothing , Nothing ) -> This  (singleton x)
    (Just _  , Nothing ) -> This  xs0
    (Nothing , Just zs') -> These (singleton x) zs'
    (Just ys', Just zs') -> These (x <| ys')    zs'
  where
    (ys, zs) = Seq.splitAt (n - 1) xs
{-# INLINABLE splitAt #-}

zip :: NESeq a -> NESeq b -> NESeq (a, b)
zip (x :<|| xs) (y :<|| ys) = (x, y) :<|| Seq.zip xs ys
{-# INLINE zip #-}

zipWith :: (a -> b -> c) -> NESeq a -> NESeq b -> NESeq c
zipWith f (x :<|| xs) (y :<|| ys) = f x y :<|| Seq.zipWith f xs ys
{-# INLINE zipWith #-}

zip3 :: NESeq a -> NESeq b -> NESeq c -> NESeq (a, b, c)
zip3 (x :<|| xs) (y :<|| ys) (z :<|| zs) = (x, y, z) :<|| Seq.zip3 xs ys zs
{-# INLINE zip3 #-}

zipWith3 :: (a -> b -> c -> d) -> NESeq a -> NESeq b -> NESeq c -> NESeq d
zipWith3 f (x :<|| xs) (y :<|| ys) (z :<|| zs) = f x y z :<|| Seq.zipWith3 f xs ys zs
{-# INLINE zipWith3 #-}

zip4 :: NESeq a -> NESeq b -> NESeq c -> NESeq d -> NESeq (a, b, c, d)
zip4 (x :<|| xs) (y :<|| ys) (z :<|| zs) (r :<|| rs) = (x, y, z, r) :<|| Seq.zip4 xs ys zs rs
{-# INLINE zip4 #-}

zipWith4 :: (a -> b -> c -> d -> e) -> NESeq a -> NESeq b -> NESeq c -> NESeq d -> NESeq e
zipWith4 f (x :<|| xs) (y :<|| ys) (z :<|| zs) (r :<|| rs) = f x y z r :<|| Seq.zipWith4 f xs ys zs rs
{-# INLINE zipWith4 #-}

unzip :: NESeq (a, b) -> (NESeq a, NESeq b)
unzip ((x, y) :<|| xys) = bimap (x :<||) (y :<||) . Seq.unzip $ xys
{-# INLINE unzip #-}

unzipWith :: (a -> (b, c)) -> NESeq a -> (NESeq b, NESeq c)
unzipWith f (x :<|| xs) = bimap (y :<||) (z :<||) . Seq.unzipWith f $ xs
  where
    (y, z) = f x
{-# INLINE unzipWith #-}