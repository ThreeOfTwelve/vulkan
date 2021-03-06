{-# language CPP #-}
module Vulkan.Core10.Enums.DescriptorPoolCreateFlagBits  ( DescriptorPoolCreateFlagBits( DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT
                                                                                       , DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT
                                                                                       , ..
                                                                                       )
                                                         , DescriptorPoolCreateFlags
                                                         ) where

import GHC.Read (choose)
import GHC.Read (expectP)
import GHC.Read (parens)
import GHC.Show (showParen)
import GHC.Show (showString)
import Numeric (showHex)
import Text.ParserCombinators.ReadPrec ((+++))
import Text.ParserCombinators.ReadPrec (prec)
import Text.ParserCombinators.ReadPrec (step)
import Data.Bits (Bits)
import Data.Bits (FiniteBits)
import Foreign.Storable (Storable)
import GHC.Read (Read(readPrec))
import Text.Read.Lex (Lexeme(Ident))
import Vulkan.Core10.FundamentalTypes (Flags)
import Vulkan.Zero (Zero)
-- | VkDescriptorPoolCreateFlagBits - Bitmask specifying certain supported
-- operations on a descriptor pool
--
-- = See Also
--
-- 'DescriptorPoolCreateFlags'
newtype DescriptorPoolCreateFlagBits = DescriptorPoolCreateFlagBits Flags
  deriving newtype (Eq, Ord, Storable, Zero, Bits, FiniteBits)

-- | 'DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT' specifies that
-- descriptor sets /can/ return their individual allocations to the pool,
-- i.e. all of 'Vulkan.Core10.DescriptorSet.allocateDescriptorSets',
-- 'Vulkan.Core10.DescriptorSet.freeDescriptorSets', and
-- 'Vulkan.Core10.DescriptorSet.resetDescriptorPool' are allowed.
-- Otherwise, descriptor sets allocated from the pool /must/ not be
-- individually freed back to the pool, i.e. only
-- 'Vulkan.Core10.DescriptorSet.allocateDescriptorSets' and
-- 'Vulkan.Core10.DescriptorSet.resetDescriptorPool' are allowed.
pattern DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT = DescriptorPoolCreateFlagBits 0x00000001
-- | 'DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT' specifies that descriptor
-- sets allocated from this pool /can/ include bindings with the
-- 'Vulkan.Core12.Enums.DescriptorBindingFlagBits.DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT'
-- bit set. It is valid to allocate descriptor sets that have bindings that
-- do not set the
-- 'Vulkan.Core12.Enums.DescriptorBindingFlagBits.DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT'
-- bit from a pool that has 'DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT'
-- set.
pattern DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT = DescriptorPoolCreateFlagBits 0x00000002

type DescriptorPoolCreateFlags = DescriptorPoolCreateFlagBits

instance Show DescriptorPoolCreateFlagBits where
  showsPrec p = \case
    DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT -> showString "DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT"
    DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT -> showString "DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT"
    DescriptorPoolCreateFlagBits x -> showParen (p >= 11) (showString "DescriptorPoolCreateFlagBits 0x" . showHex x)

instance Read DescriptorPoolCreateFlagBits where
  readPrec = parens (choose [("DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT", pure DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT)
                            , ("DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT", pure DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT)]
                     +++
                     prec 10 (do
                       expectP (Ident "DescriptorPoolCreateFlagBits")
                       v <- step readPrec
                       pure (DescriptorPoolCreateFlagBits v)))

