module Main(main) where
import OrderBook
import Control.Concurrent.STM
import Test.QuickCheck
import Control.Concurrent

main :: IO ()
main = do
    ordBook            <- atomically $ newTOrderBook
    (ord1, ord2, ord3) <- generate (arbitrary :: Gen (Header Int, Header Int, Header Int))
    join               <- newEmptyMVar
    _                  <- forkIO (do
                            _ <- atomically $ addTOrderBook ord1 ordBook
                            _ <- atomically $ addTOrderBook ord2 ordBook
                            putMVar join ())
    _                  <- atomically $ addTOrderBook ord3 ordBook
    _                  <- readMVar join
    ordBookStr         <- showTOrderBook ordBook
    putStr ordBookStr
