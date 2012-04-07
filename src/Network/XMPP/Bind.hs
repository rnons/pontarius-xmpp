{-# LANGUAGE OverloadedStrings #-}

module Network.XMPP.Bind where

import Control.Monad.Trans.State

import Data.Text as Text

import Data.XML.Pickle
import Data.XML.Types

import Network.XMPP.Monad
import Network.XMPP.Types
import Network.XMPP.Pickle
import Network.XMPP.Concurrent

bindBody :: Maybe Text -> Element
bindBody rsrc = (pickleElem
                    (bindP . xpOption $ xpElemNodes "resource" (xpContent xpId))
                     rsrc
                 )

bindReqIQ :: Maybe Text -> Stanza
bindReqIQ rsrc= SIQ $ IQ Nothing Nothing "bind" Set (bindBody rsrc)

jidP :: PU [Node] JID
jidP = bindP $ xpElemNodes "jid" (xpContent xpPrim)

xmppBind :: Maybe Text -> XMPPMonad ()
xmppBind res = do
  push $ bindReqIQ res
  answer <- pull
  let SIQ (IQ Nothing Nothing _ Result b) = answer
  let (JID _n _d (Just r)) = unpickleElem jidP b
  modify (\s -> s{sResource = Just r})

bindP  :: PU [Node] b -> PU [Node] b
bindP c = xpElemNodes "{urn:ietf:params:xml:ns:xmpp-bind}bind" c


xmppThreadedBind  :: Maybe Text -> XMPPThread Text
xmppThreadedBind rsrc = do
   answer <- sendIQ' Nothing Set (bindBody rsrc)
   let (IQ Nothing Nothing _ Result b) = answer
   let (JID _n _d (Just r)) = unpickleElem jidP b
   return r



