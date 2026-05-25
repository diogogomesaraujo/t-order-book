--
-- Transactional OrderBook a.k.a TOrderBook
--
-- References:
-- https://medium.com/@thinhnguyen042002/lets-build-a-stock-exchange-from-scratch-18459611ad83
--

module OrderBook ( OrderType,
                  TOrderBook,
                  newTOrderBook,
                  addTOrderBook,
                  removeTOrderBook,
                  Order,
                  newOrder,
                  showTOrderBook ) where

import TPriorityQueue
import Control.Concurrent.STM
import Test.QuickCheck

type Timestamp = Int

data OrderType = Buy | Sell
    deriving (Show, Eq)

instance Arbitrary OrderType where
    arbitrary = elements [Buy, Sell]

data Header c = Header {
    orderType   :: OrderType,
    limitAmount :: c
} deriving (Show, Eq)

newHeader :: Ord c => OrderType -> c -> Header c
newHeader t l =
    Header { orderType   = t,
             limitAmount = l }

data Order c = Order {
    header      :: Header c,
    timestamp   :: Timestamp
} deriving (Show, Eq)

instance Ord c => Ord (Order c) where
    compare ordA ordB =
        compare (limitAmount $ header ordA, timestamp ordA)
                (limitAmount $ header ordB, timestamp ordB)

newOrder :: Ord c => Header c -> Timestamp -> Order c
newOrder h ts =
    Order { header    = h,
            timestamp = ts }

data TOrderBook c = TOrderBook {
    bidOrders :: TPriorityQueue (Order c),
    askOrders :: TPriorityQueue (Order c),
    clock     :: TVar (Timestamp)
}

stamp :: Ord c => TOrderBook c -> Header c -> STM (Order c)
stamp ordBook h = do
    ts    <- readTVar $ clock ordBook
    _     <- writeTVar (clock ordBook) (ts + 1)
    return $ newOrder h ts

newTOrderBook :: Ord c => STM (TOrderBook c)
newTOrderBook = do
    bidOrds <- newTPriorityQueue
    askOrds <- newTPriorityQueue
    clk     <- newTVar 0
    return   $ TOrderBook { clock     = clk,
                            bidOrders = bidOrds,
                            askOrders = askOrds }

addTOrderBook :: Ord c => Header c -> TOrderBook c -> STM ()
addTOrderBook hd ordBook = do
    ord <- stamp ordBook hd
    case orderType hd of
        Buy  -> insertTPriorityQueue
                    ord (bidOrders ordBook)
        Sell -> insertTPriorityQueue
                    ord (askOrders ordBook)

removeTOrderBook :: Ord c => OrderType -> TOrderBook c -> STM (Maybe (Order c))
removeTOrderBook t ordBook = do
    case t of
        Buy  -> pollTPriorityQueue $ bidOrders ordBook
        Sell -> pollTPriorityQueue $ askOrders ordBook

showTOrderBook :: (Ord c, Show c) => TOrderBook c -> STM String
showTOrderBook ordBook = do
    bidOrds <- showTPriorityQueue $ bidOrders ordBook
    askOrds <- showTPriorityQueue $ askOrders ordBook
    clk     <- readTVar $ clock ordBook
    return   $ show (bidOrds, askOrds, clk)

--
-- Testing
--

instance (Ord c, Arbitrary c) => Arbitrary (Header c) where
    arbitrary = do
        ordType        <- arbitrary
        ordLimitAmount <- arbitrary
        return $ newHeader ordType ordLimitAmount
