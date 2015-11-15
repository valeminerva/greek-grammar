{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Text.Greek.Script.Syllable where

--import Text.Greek.FileReference
--import Text.Greek.Parse.Utility
--import Text.Greek.Script.Unit (Unit)
--import Text.Parsec.Error (ParseError)
--import Text.Parsec.Prim
--import Text.Parsec.Combinator
--import qualified Text.Greek.Script.Abstract as Abstract
--import qualified Text.Greek.Script.Mark as Mark
--import qualified Text.Greek.Script.Unit as Unit

import qualified Control.Lens as Lens
import qualified Text.Greek.Script.Abstract as Abstract
import qualified Text.Greek.Script.Mark as Mark

data StartVocalic v
  = StartVocalicSingle v
  | StartVocalicDiaeresis v
  | StartVocalicIota v
  | StartVocalicDiphthong v v
  deriving (Eq, Ord, Show)

instance Functor StartVocalic where
  fmap f (StartVocalicSingle v) = StartVocalicSingle (f v)
  fmap f (StartVocalicDiaeresis v) = StartVocalicDiaeresis (f v)
  fmap f (StartVocalicIota v) = StartVocalicIota (f v)
  fmap f (StartVocalicDiphthong v1 v2) = StartVocalicDiphthong (f v1) (f v2)

type Start m = Either (StartVocalic (Abstract.Vowel, m)) (Abstract.Consonant, m)

makeStartVocalic :: [(Abstract.VowelConsonant, Mark.Group Maybe)] -> [Start (Mark.Group Maybe)]
makeStartVocalic = foldr go []
  where
    go (Right a, c) xs = Right (a, c) : xs
    go (Left a, c@(_, _, Just Mark.SyllabicIotaSubscript)) xs = Left (StartVocalicIota (a, c)) : xs
    go (Left a, c@(_, _, Just Mark.SyllabicDiaeresis)) xs = Left (StartVocalicDiaeresis (a, c)) : xs
    go (Left a, c@(_, _, Nothing)) [] = Left (StartVocalicSingle (a, c)) : []
    go (Left a, c@(_, _, Nothing)) (Left (StartVocalicSingle v@(vw, _)) : xs) | isCombiner vw = Left (StartVocalicDiphthong (a, c) v) : xs
    go (Left a, c) xs = Left (StartVocalicSingle (a, c)) : xs

    isCombiner Abstract.V_ι = True
    isCombiner Abstract.V_υ = True
    isCombiner _ = False

data Diphthong = D_αι | D_αυ | D_ει | D_ευ | D_ηυ | D_οι | D_ου | D_υι deriving (Eq, Ord, Show)
data ImproperDiphthong = I_α | I_η | I_ω deriving (Eq, Ord, Show)

data Vocalic m
  = VocalicSingle Abstract.Vowel m
  | VocalicIota ImproperDiphthong m
  | VocalicDiphthong Diphthong m
  deriving (Eq, Ord, Show)

type VocalicEither mv c = Either (Vocalic mv) c
type VocalicConsonant mv mc = VocalicEither mv (Abstract.Consonant, mc)

type ConsonantCluster m = [(Abstract.Consonant, m)]

newtype Count = Count Int deriving (Eq, Ord, Show, Num)
newtype VocalicSingleCount = VocalicSingleCount Int deriving (Eq, Ord, Show, Num)
newtype ImproperDiphthongCount = ImproperDiphthongCount Int deriving (Eq, Ord, Show, Num)
newtype DiphthongCount = DiphthongCount Int deriving (Eq, Ord, Show, Num)

getSyllableCount :: VocalicConsonant a b -> Count
getSyllableCount (Left _) = 1
getSyllableCount (Right _) = 0

getVocalicSingleCount :: VocalicConsonant a b -> VocalicSingleCount
getVocalicSingleCount (Left (VocalicSingle _ _)) = 1
getVocalicSingleCount _ = 0

getImproperDiphthongCount :: VocalicConsonant a b -> ImproperDiphthongCount
getImproperDiphthongCount (Left (VocalicIota _ _)) = 1
getImproperDiphthongCount _ = 0

getDiphthongCount :: VocalicConsonant a b -> DiphthongCount
getDiphthongCount (Left (VocalicDiphthong _ _)) = 1
getDiphthongCount _ = 0

validateVocalicConsonant :: Start (Mark.Group Maybe) -> Maybe (VocalicConsonant (Mark.AccentBreathing Maybe) (Maybe Mark.Breathing))
validateVocalicConsonant x = Lens._Left validateStartVocalic x >>= Lens._Right validateConsonantBreathing

validateStartVocalic :: StartVocalic (Abstract.Vowel, Mark.Group Maybe) -> Maybe (Vocalic (Mark.AccentBreathing Maybe))
validateStartVocalic (StartVocalicSingle (v, (a, b, Nothing))) =
  Just $ VocalicSingle v (a, b)
validateStartVocalic (StartVocalicDiaeresis (v, (a, b, Just Mark.SyllabicDiaeresis))) =
  Just $ VocalicSingle v (a, b)
validateStartVocalic (StartVocalicIota (v, (a, b, Just Mark.SyllabicIotaSubscript))) =
  VocalicIota <$> vowelToImproperDiphthong v <*> pure (a, b)
validateStartVocalic (StartVocalicDiphthong (v1, (Nothing, Nothing, Nothing)) (v2, (a, b, Nothing))) =
  VocalicDiphthong <$> vowelPairToDiphthong v1 v2 <*> pure (a, b)
validateStartVocalic _ =
  Nothing

vowelToImproperDiphthong :: Abstract.Vowel -> Maybe ImproperDiphthong
vowelToImproperDiphthong Abstract.V_α = Just I_α
vowelToImproperDiphthong Abstract.V_η = Just I_η
vowelToImproperDiphthong Abstract.V_ω = Just I_ω
vowelToImproperDiphthong _ = Nothing

vowelPairToDiphthong :: Abstract.Vowel -> Abstract.Vowel -> Maybe Diphthong
vowelPairToDiphthong Abstract.V_α Abstract.V_ι = Just D_αι
vowelPairToDiphthong Abstract.V_α Abstract.V_υ = Just D_αυ
vowelPairToDiphthong Abstract.V_ε Abstract.V_ι = Just D_ει
vowelPairToDiphthong Abstract.V_ε Abstract.V_υ = Just D_ευ
vowelPairToDiphthong Abstract.V_η Abstract.V_υ = Just D_ηυ
vowelPairToDiphthong Abstract.V_ο Abstract.V_ι = Just D_οι
vowelPairToDiphthong Abstract.V_ο Abstract.V_υ = Just D_ου
vowelPairToDiphthong Abstract.V_υ Abstract.V_ι = Just D_υι
vowelPairToDiphthong _ _ = Nothing

validateConsonantBreathing :: (Abstract.Consonant, Mark.Group Maybe) -> Maybe (Abstract.Consonant, Maybe Mark.Breathing)
validateConsonantBreathing (x, (Nothing, b, Nothing)) = Just (x, b)
validateConsonantBreathing _ = Nothing

vocalicToSingle :: Vocalic m -> [Abstract.Vowel]
vocalicToSingle (VocalicSingle v _) = [v]
vocalicToSingle _ = []

vocalicToImproperDiphthong :: Vocalic m -> [ImproperDiphthong]
vocalicToImproperDiphthong (VocalicIota d _) = [d]
vocalicToImproperDiphthong _ = []

vocalicToDiphthong :: Vocalic m -> [Diphthong]
vocalicToDiphthong (VocalicDiphthong d _) = [d]
vocalicToDiphthong _ = []


--data Vocalic a b c
--  = OneVowel a
--  | IotaSubscriptVowel b
--  | TwoVowel c
--  deriving (Eq, Ord, Show)

--type VocalicSimple a = Vocalic a a (a, a)
--type VocalicVowel = VocalicSimple Abstract.Vowel
--type VocalicPair = VocalicSimple (Abstract.Vowel, FileCharReference)

--type VocalicConsonant = Either VocalicPair (Abstract.Consonant, FileCharReference)

--type UnitLetter = Unit.UnitLetter Abstract.VowelConsonant Mark.AllPair
--type UnitVocalicConsonant = Unit VocalicConsonant Mark.AccentBreathingAllPair

--type UnitLetterParser a = Parser [UnitLetter] a

--primUnitLetter :: String -> (UnitLetter -> Maybe a) -> Parser [UnitLetter] a
--primUnitLetter p = primMaybe p (^. Unit.unitItem . _2 . fileCharReferenceLine)

--isIotaSubscriptVowel :: Abstract.Vowel -> Bool
--isIotaSubscriptVowel v
--  =  v == Abstract.V_α
--  || v == Abstract.V_η
--  || v == Abstract.V_ω

--iotaSubscriptParser :: UnitLetterParser UnitVocalicConsonant
--iotaSubscriptParser = primUnitLetter "Iota subscript vowel" go
--  where
--    go u
--      | (Left v, r) <- u ^. Unit.unitItem
--      , isIotaSubscriptVowel v
--      , m <- u ^. Unit.unitMarks
--      , Just (Mark.IotaSubscriptAll, _) <- m ^. _3
--      = Just $ Unit.Unit (Left $ IotaSubscriptVowel (v, r)) (Mark.getAccentBreathingAllPair m)
--    go _ = Nothing

--isTwoSoundVowel :: Abstract.Vowel -> Bool
--isTwoSoundVowel v
--  =  v == Abstract.V_ι
--  || v == Abstract.V_υ

--diaeresisVowelParser :: UnitLetterParser UnitVocalicConsonant
--diaeresisVowelParser = primUnitLetter "Diaeresis vowel" go
--  where
--    go u
--      | (Left v, r) <- u ^. Unit.unitItem
--      , isTwoSoundVowel v
--      , m <- u ^. Unit.unitMarks
--      , Just (Mark.DiaeresisAll, _) <- m ^. _3
--      = Just $ Unit.Unit (Left $ OneVowel (v, r)) (Mark.getAccentBreathingAllPair m)
--    go _ = Nothing

--midTwoSoundFirstVowelParser :: UnitLetterParser (Abstract.Vowel, FileCharReference)
--midTwoSoundFirstVowelParser = primUnitLetter "Mid two sound vowel 1" go
--  where
--    go u
--      | (Left v, r) <- u ^. Unit.unitItem
--      , m <- u ^. Unit.unitMarks
--      , (Nothing, Nothing, Nothing) <- m
--      = Just (v, r)
--    go _ = Nothing

--midTwoSoundSecondVowelParser :: UnitLetterParser ((Abstract.Vowel, FileCharReference), Mark.AccentBreathingAllPair)
--midTwoSoundSecondVowelParser = primUnitLetter "Mid two sound vowel 2" go
--  where
--    go u
--      | (Left v, r) <- u ^. Unit.unitItem
--      , m <- u ^. Unit.unitMarks
--      , Nothing <- m ^. _3
--      = Just ((v, r), Mark.getAccentBreathingAllPair m)
--    go _ = Nothing

--midTwoSoundParser :: UnitLetterParser UnitVocalicConsonant
--midTwoSoundParser = do
--  v1p <- midTwoSoundFirstVowelParser
--  (v2p, m) <- midTwoSoundSecondVowelParser
--  return $ Unit.Unit (Left $ TwoVowel (v1p, v2p)) m

--consonantParser :: UnitLetterParser UnitVocalicConsonant
--consonantParser = primUnitLetter "Consonant" go
--  where
--    go u
--      | (Right c, r) <- u ^. Unit.unitItem
--      , m <- u ^. Unit.unitMarks
--      , Nothing <- m ^. _3
--      = Just $ Unit.Unit (Right (c, r)) (Mark.getAccentBreathingAllPair m)
--    go _ = Nothing

--singleVowelParser :: UnitLetterParser UnitVocalicConsonant
--singleVowelParser = primUnitLetter "Single vowel" go
--  where
--    go u
--      | (Left v, r) <- u ^. Unit.unitItem
--      , False <- isTwoSoundVowel v
--      , m <- u ^. Unit.unitMarks
--      , Nothing <- m ^. _3
--      = Just $ Unit.Unit (Left $ OneVowel (v, r)) (Mark.getAccentBreathingAllPair m)
--    go _ = Nothing

--vocalicConsonantParser :: UnitLetterParser UnitVocalicConsonant
--vocalicConsonantParser
--  =   consonantParser
--  <|> iotaSubscriptParser
--  <|> diaeresisVowelParser
--  <|> try midTwoSoundParser
--  <|> singleVowelParser
--  <?> "VocalicConsonant"

--parseVocalicSyllable :: [UnitLetter] -> Either ParseError [UnitVocalicConsonant]
--parseVocalicSyllable = parse (many1 vocalicConsonantParser <* eof) ""
