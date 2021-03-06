{-# OPTIONS_HADDOCK hide #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoMonomorphismRestriction #-}

module Network.Xmpp.IM.Presence where

import Data.Default
import Data.Text (Text)
import Data.XML.Pickle
import Data.XML.Types
import Network.Xmpp.Types

data ShowStatus = StatusAway
                | StatusChat
                | StatusDnd
                | StatusXa deriving (Read, Show)

data IMPresence = IMP { showStatus :: Maybe ShowStatus
                      , status     :: Maybe Text
                      , priority   :: Maybe Int
                      } deriving Show

imPresence :: IMPresence
imPresence = IMP { showStatus = Nothing
                 , status     = Nothing
                 , priority   = Nothing
                 }

instance Default IMPresence where
    def = imPresence

-- | Try to extract RFC6121 IM presence information from presence stanza.
-- Returns Nothing when the data is malformed, (Just IMPresence) otherwise.
getIMPresence :: Presence -> Maybe IMPresence
getIMPresence pres = case unpickle xpIMPresence (presencePayload pres) of
    Left _ -> Nothing
    Right r -> Just r

withIMPresence :: IMPresence -> Presence -> Presence
withIMPresence imPres pres = pres{presencePayload = presencePayload pres
                                                   ++ pickleTree xpIMPresence
                                                                 imPres}

--
-- Picklers
--

xpIMPresence :: PU [Element] IMPresence
xpIMPresence = xpUnliftElems .
               xpWrap (\(s, st, p) -> IMP s st p)
                      (\(IMP s st p) -> (s, st, p)) .
               xpClean $
               xp3Tuple
                  (xpOption $ xpElemNodes "{jabber:client}show"
                     (xpContent xpShow))
                  (xpOption $ xpElemNodes "{jabber:client}status"
                     (xpContent xpText))
                  (xpOption $ xpElemNodes "{jabber:client}priority"
                     (xpContent xpPrim))

xpShow :: PU Text ShowStatus
xpShow = ("xpShow", "") <?>
        xpPartial ( \input -> case showStatusFromText input of
                                   Nothing -> Left "Could not parse show status."
                                   Just j -> Right j)
                  showStatusToText
  where
    showStatusFromText "away" = Just StatusAway
    showStatusFromText "chat" = Just StatusChat
    showStatusFromText "dnd" = Just StatusDnd
    showStatusFromText "xa" = Just StatusXa
    showStatusFromText _ = Nothing
    showStatusToText StatusAway = "away"
    showStatusToText StatusChat = "chat"
    showStatusToText StatusDnd = "dnd"
    showStatusToText StatusXa = "xa"
