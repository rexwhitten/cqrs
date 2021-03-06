{-# LANGUAGE DeriveGeneric #-}
module Data.CQRS.Types.Chunk
    ( Chunk
    , chunks
    , fromList
    , fromNonEmpty
    , toList
    ) where

import           Control.Applicative ((<$>))
import           Control.DeepSeq (NFData(..))
import           Data.Bifunctor (Bifunctor(..))
import           GHC.Generics (Generic)
import           Data.CQRS.Internal.PersistedEvent
import           Data.List.NonEmpty (NonEmpty)
import qualified Data.List.NonEmpty as NEL

-- A non-empty chunk of events for a single aggregate.
data Chunk i e = Chunk !i !(NonEmpty (PersistedEvent e))
  deriving (Show, Eq, Generic)

-- Instances
instance Bifunctor Chunk where
  bimap f g (Chunk aggregateId events) = Chunk aggregateId' events'
    where
      events' = NEL.map (fmap g) events
      aggregateId' = f aggregateId

instance (NFData e, NFData i) => NFData (Chunk i e)

-- | Create a chunk from an aggregate ID and a list of events.
fromList :: i -> [PersistedEvent e] -> Maybe (Chunk i e)
fromList i es = fromNonEmpty i <$> NEL.nonEmpty es

-- | Create a chunk from an aggregate ID and a non-empty list of events.
fromNonEmpty :: i -> NonEmpty (PersistedEvent e) -> Chunk i e
fromNonEmpty = Chunk

-- | Group events into chunks based on aggregate ID.
chunks :: Eq i => NonEmpty (PersistedEvent' i e) -> NonEmpty (Chunk i e)
chunks persistedEvents =
  NEL.map f $ NEL.groupBy1 (\a b -> pepAggregateId a == pepAggregateId b) persistedEvents
  where
    f g = Chunk aggregateId events
           where events = NEL.map shrink g
                 aggregateId = pepAggregateId $ NEL.head g

-- | Convert a chunk into an identifier and a non-empty list of
-- events.
toList :: Chunk i e -> (i, NonEmpty (PersistedEvent e))
toList (Chunk i es) = (i, es)
