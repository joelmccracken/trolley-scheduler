module Main where

import           Data.List
import           Data.Maybe
import           System.Random
import           System.Random.Shuffle (shuffleM)

type ShiftList = String

type Person = String

type Schedule = [Day] --Adds Xs ("is-off") to the shift list to pair up with non-working people

data Day =
  Day Int [Shift]
  deriving (Eq, Show)

data Shift =
  Shift Char Person
  deriving (Eq, Show)

padShifts :: Int -> ShiftList -> ShiftList
padShifts nPeople shifts = shifts ++ replicate (nPeople - length shifts) 'X' --Randomly assigns people shifts

randomFillShifts :: [Person] -> ShiftList -> IO [Shift]
randomFillShifts people shifts = do
  let paddedShifts = padShifts (length people) shifts
  shuffledPeople <- shuffleM people
  return $ zipWith Shift paddedShifts shuffledPeople

randomDay :: Int -> [Person] -> ShiftList -> IO Day
randomDay day people shifts = fmap (Day day) (randomFillShifts people shifts)

getRandomSchedule :: Int -> [Person] -> ShiftList -> IO Schedule
getRandomSchedule days people shifts =
  sequence [randomDay day people shifts | day <- [1 .. days]]

generateSchedule :: Int -> [Person] -> ShiftList -> IO [Schedule]
generateSchedule days people shifts =
  catMaybes <$>
  (getRandomSchedule days people shifts >>= \s ->
     if pred s
       then return [Just s]
       else return [Nothing])
  where
    pred = noonesWorkingLongerThen 7

getStaffList :: Schedule -> [Person]
getStaffList [] = []
getStaffList (Day _ shifts:_) = map person shifts
  where
    person (Shift _ p) = p

hasOff :: Person -> Day -> Bool
p `hasOff` (Day _ shifts) = all isOff shifts
  where
    isOff (Shift s q) = p /= q || s == 'X'

longestStreak :: Eq e => e -> [e] -> Int
longestStreak e =
  maximum . (0 :) . map length . filter (e `matchesGroup`) . group
  where
    matchesGroup _ []     = False
    matchesGroup e (x:xs) = e == x

getStretchList :: Schedule -> [Int]
getStretchList sched =
  map
    (\person -> longestStreak False $ map (\day -> person `hasOff` day) sched)
    staffList
  where
    staffList = getStaffList sched
    -- Restrictions:

noonesWorkingLongerThen :: Int -> Schedule -> Bool
noonesWorkingLongerThen daysLong sched =
  not . any (> daysLong) $ getStretchList sched

main :: IO ()
main = do
  let days = 30 -- The full rotation length
      people = ["B", "E", "K", "T", "R", "C"] -- Volunteer list
      shifts = "123" -- Each char is a seperate shift
  found <- generateSchedule days people shifts
  print found
