module TPriorityQueue( TPriorityQueue,
                       newTPriorityQueue,
                       insertTPriorityQueue,
                       pollTPriorityQueue,
                       showTPriorityQueue ) where

import Control.Concurrent.STM
import Data.PQueue.Min

type TPriorityQueue v = TVar (MinQueue v)

newTPriorityQueue :: Ord v => STM (TPriorityQueue v)
newTPriorityQueue = newTVar (empty)

insertTPriorityQueue :: Ord v => v -> TPriorityQueue v -> STM ()
insertTPriorityQueue v q = do
    pQueue <- readTVar q
    writeTVar q $ insert v pQueue

pollTPriorityQueue :: Ord v => TPriorityQueue v -> STM (Maybe v)
pollTPriorityQueue q = do
    pQueue <- readTVar q
    case minView pQueue of
        Just (minV, newPQueue) -> do
            writeTVar q newPQueue
            return $  Just minV
        Nothing ->
            return Nothing

showTPriorityQueue :: (Ord v, Show v) => TPriorityQueue v -> IO String
showTPriorityQueue q = do
    pQueue <- atomically $ readTVar q
    return $  show (toList pQueue)
