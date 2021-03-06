{-# language CPP #-}
module Vulkan.Core10.Enums.BlendFactor  (BlendFactor( BLEND_FACTOR_ZERO
                                                    , BLEND_FACTOR_ONE
                                                    , BLEND_FACTOR_SRC_COLOR
                                                    , BLEND_FACTOR_ONE_MINUS_SRC_COLOR
                                                    , BLEND_FACTOR_DST_COLOR
                                                    , BLEND_FACTOR_ONE_MINUS_DST_COLOR
                                                    , BLEND_FACTOR_SRC_ALPHA
                                                    , BLEND_FACTOR_ONE_MINUS_SRC_ALPHA
                                                    , BLEND_FACTOR_DST_ALPHA
                                                    , BLEND_FACTOR_ONE_MINUS_DST_ALPHA
                                                    , BLEND_FACTOR_CONSTANT_COLOR
                                                    , BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR
                                                    , BLEND_FACTOR_CONSTANT_ALPHA
                                                    , BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA
                                                    , BLEND_FACTOR_SRC_ALPHA_SATURATE
                                                    , BLEND_FACTOR_SRC1_COLOR
                                                    , BLEND_FACTOR_ONE_MINUS_SRC1_COLOR
                                                    , BLEND_FACTOR_SRC1_ALPHA
                                                    , BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA
                                                    , ..
                                                    )) where

import GHC.Read (choose)
import GHC.Read (expectP)
import GHC.Read (parens)
import GHC.Show (showParen)
import GHC.Show (showString)
import GHC.Show (showsPrec)
import Text.ParserCombinators.ReadPrec ((+++))
import Text.ParserCombinators.ReadPrec (prec)
import Text.ParserCombinators.ReadPrec (step)
import Foreign.Storable (Storable)
import Data.Int (Int32)
import GHC.Read (Read(readPrec))
import Text.Read.Lex (Lexeme(Ident))
import Vulkan.Zero (Zero)
-- | VkBlendFactor - Framebuffer blending factors
--
-- = Description
--
-- The semantics of each enum value is described in the table below:
--
-- +-----------------------------------------+---------------------+--------+
-- | 'BlendFactor'                           | RGB Blend Factors   | Alpha  |
-- |                                         | (Sr,Sg,Sb) or       | Blend  |
-- |                                         | (Dr,Dg,Db)          | Factor |
-- |                                         |                     | (Sa or |
-- |                                         |                     | Da)    |
-- +=========================================+=====================+========+
-- | 'BLEND_FACTOR_ZERO'                     | (0,0,0)             | 0      |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_ONE'                      | (1,1,1)             | 1      |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_SRC_COLOR'                | (Rs0,Gs0,Bs0)       | As0    |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_ONE_MINUS_SRC_COLOR'      | (1-Rs0,1-Gs0,1-Bs0) | 1-As0  |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_DST_COLOR'                | (Rd,Gd,Bd)          | Ad     |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_ONE_MINUS_DST_COLOR'      | (1-Rd,1-Gd,1-Bd)    | 1-Ad   |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_SRC_ALPHA'                | (As0,As0,As0)       | As0    |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_ONE_MINUS_SRC_ALPHA'      | (1-As0,1-As0,1-As0) | 1-As0  |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_DST_ALPHA'                | (Ad,Ad,Ad)          | Ad     |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_ONE_MINUS_DST_ALPHA'      | (1-Ad,1-Ad,1-Ad)    | 1-Ad   |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_CONSTANT_COLOR'           | (Rc,Gc,Bc)          | Ac     |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR' | (1-Rc,1-Gc,1-Bc)    | 1-Ac   |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_CONSTANT_ALPHA'           | (Ac,Ac,Ac)          | Ac     |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA' | (1-Ac,1-Ac,1-Ac)    | 1-Ac   |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_SRC_ALPHA_SATURATE'       | (f,f,f); f =        | 1      |
-- |                                         | min(As0,1-Ad)       |        |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_SRC1_COLOR'               | (Rs1,Gs1,Bs1)       | As1    |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_ONE_MINUS_SRC1_COLOR'     | (1-Rs1,1-Gs1,1-Bs1) | 1-As1  |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_SRC1_ALPHA'               | (As1,As1,As1)       | As1    |
-- +-----------------------------------------+---------------------+--------+
-- | 'BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA'     | (1-As1,1-As1,1-As1) | 1-As1  |
-- +-----------------------------------------+---------------------+--------+
--
-- Blend Factors
--
-- In this table, the following conventions are used:
--
-- -   Rs0,Gs0,Bs0 and As0 represent the first source color R, G, B, and A
--     components, respectively, for the fragment output location
--     corresponding to the color attachment being blended.
--
-- -   Rs1,Gs1,Bs1 and As1 represent the second source color R, G, B, and A
--     components, respectively, used in dual source blending modes, for
--     the fragment output location corresponding to the color attachment
--     being blended.
--
-- -   Rd,Gd,Bd and Ad represent the R, G, B, and A components of the
--     destination color. That is, the color currently in the corresponding
--     color attachment for this fragment\/sample.
--
-- -   Rc,Gc,Bc and Ac represent the blend constant R, G, B, and A
--     components, respectively.
--
-- = See Also
--
-- 'Vulkan.Core10.Pipeline.PipelineColorBlendAttachmentState'
newtype BlendFactor = BlendFactor Int32
  deriving newtype (Eq, Ord, Storable, Zero)

-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_ZERO"
pattern BLEND_FACTOR_ZERO = BlendFactor 0
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_ONE"
pattern BLEND_FACTOR_ONE = BlendFactor 1
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_SRC_COLOR"
pattern BLEND_FACTOR_SRC_COLOR = BlendFactor 2
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_ONE_MINUS_SRC_COLOR"
pattern BLEND_FACTOR_ONE_MINUS_SRC_COLOR = BlendFactor 3
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_DST_COLOR"
pattern BLEND_FACTOR_DST_COLOR = BlendFactor 4
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_ONE_MINUS_DST_COLOR"
pattern BLEND_FACTOR_ONE_MINUS_DST_COLOR = BlendFactor 5
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_SRC_ALPHA"
pattern BLEND_FACTOR_SRC_ALPHA = BlendFactor 6
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA"
pattern BLEND_FACTOR_ONE_MINUS_SRC_ALPHA = BlendFactor 7
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_DST_ALPHA"
pattern BLEND_FACTOR_DST_ALPHA = BlendFactor 8
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_ONE_MINUS_DST_ALPHA"
pattern BLEND_FACTOR_ONE_MINUS_DST_ALPHA = BlendFactor 9
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_CONSTANT_COLOR"
pattern BLEND_FACTOR_CONSTANT_COLOR = BlendFactor 10
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR"
pattern BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR = BlendFactor 11
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_CONSTANT_ALPHA"
pattern BLEND_FACTOR_CONSTANT_ALPHA = BlendFactor 12
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA"
pattern BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA = BlendFactor 13
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_SRC_ALPHA_SATURATE"
pattern BLEND_FACTOR_SRC_ALPHA_SATURATE = BlendFactor 14
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_SRC1_COLOR"
pattern BLEND_FACTOR_SRC1_COLOR = BlendFactor 15
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_ONE_MINUS_SRC1_COLOR"
pattern BLEND_FACTOR_ONE_MINUS_SRC1_COLOR = BlendFactor 16
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_SRC1_ALPHA"
pattern BLEND_FACTOR_SRC1_ALPHA = BlendFactor 17
-- No documentation found for Nested "VkBlendFactor" "VK_BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA"
pattern BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA = BlendFactor 18
{-# complete BLEND_FACTOR_ZERO,
             BLEND_FACTOR_ONE,
             BLEND_FACTOR_SRC_COLOR,
             BLEND_FACTOR_ONE_MINUS_SRC_COLOR,
             BLEND_FACTOR_DST_COLOR,
             BLEND_FACTOR_ONE_MINUS_DST_COLOR,
             BLEND_FACTOR_SRC_ALPHA,
             BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
             BLEND_FACTOR_DST_ALPHA,
             BLEND_FACTOR_ONE_MINUS_DST_ALPHA,
             BLEND_FACTOR_CONSTANT_COLOR,
             BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR,
             BLEND_FACTOR_CONSTANT_ALPHA,
             BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA,
             BLEND_FACTOR_SRC_ALPHA_SATURATE,
             BLEND_FACTOR_SRC1_COLOR,
             BLEND_FACTOR_ONE_MINUS_SRC1_COLOR,
             BLEND_FACTOR_SRC1_ALPHA,
             BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA :: BlendFactor #-}

instance Show BlendFactor where
  showsPrec p = \case
    BLEND_FACTOR_ZERO -> showString "BLEND_FACTOR_ZERO"
    BLEND_FACTOR_ONE -> showString "BLEND_FACTOR_ONE"
    BLEND_FACTOR_SRC_COLOR -> showString "BLEND_FACTOR_SRC_COLOR"
    BLEND_FACTOR_ONE_MINUS_SRC_COLOR -> showString "BLEND_FACTOR_ONE_MINUS_SRC_COLOR"
    BLEND_FACTOR_DST_COLOR -> showString "BLEND_FACTOR_DST_COLOR"
    BLEND_FACTOR_ONE_MINUS_DST_COLOR -> showString "BLEND_FACTOR_ONE_MINUS_DST_COLOR"
    BLEND_FACTOR_SRC_ALPHA -> showString "BLEND_FACTOR_SRC_ALPHA"
    BLEND_FACTOR_ONE_MINUS_SRC_ALPHA -> showString "BLEND_FACTOR_ONE_MINUS_SRC_ALPHA"
    BLEND_FACTOR_DST_ALPHA -> showString "BLEND_FACTOR_DST_ALPHA"
    BLEND_FACTOR_ONE_MINUS_DST_ALPHA -> showString "BLEND_FACTOR_ONE_MINUS_DST_ALPHA"
    BLEND_FACTOR_CONSTANT_COLOR -> showString "BLEND_FACTOR_CONSTANT_COLOR"
    BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR -> showString "BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR"
    BLEND_FACTOR_CONSTANT_ALPHA -> showString "BLEND_FACTOR_CONSTANT_ALPHA"
    BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA -> showString "BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA"
    BLEND_FACTOR_SRC_ALPHA_SATURATE -> showString "BLEND_FACTOR_SRC_ALPHA_SATURATE"
    BLEND_FACTOR_SRC1_COLOR -> showString "BLEND_FACTOR_SRC1_COLOR"
    BLEND_FACTOR_ONE_MINUS_SRC1_COLOR -> showString "BLEND_FACTOR_ONE_MINUS_SRC1_COLOR"
    BLEND_FACTOR_SRC1_ALPHA -> showString "BLEND_FACTOR_SRC1_ALPHA"
    BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA -> showString "BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA"
    BlendFactor x -> showParen (p >= 11) (showString "BlendFactor " . showsPrec 11 x)

instance Read BlendFactor where
  readPrec = parens (choose [("BLEND_FACTOR_ZERO", pure BLEND_FACTOR_ZERO)
                            , ("BLEND_FACTOR_ONE", pure BLEND_FACTOR_ONE)
                            , ("BLEND_FACTOR_SRC_COLOR", pure BLEND_FACTOR_SRC_COLOR)
                            , ("BLEND_FACTOR_ONE_MINUS_SRC_COLOR", pure BLEND_FACTOR_ONE_MINUS_SRC_COLOR)
                            , ("BLEND_FACTOR_DST_COLOR", pure BLEND_FACTOR_DST_COLOR)
                            , ("BLEND_FACTOR_ONE_MINUS_DST_COLOR", pure BLEND_FACTOR_ONE_MINUS_DST_COLOR)
                            , ("BLEND_FACTOR_SRC_ALPHA", pure BLEND_FACTOR_SRC_ALPHA)
                            , ("BLEND_FACTOR_ONE_MINUS_SRC_ALPHA", pure BLEND_FACTOR_ONE_MINUS_SRC_ALPHA)
                            , ("BLEND_FACTOR_DST_ALPHA", pure BLEND_FACTOR_DST_ALPHA)
                            , ("BLEND_FACTOR_ONE_MINUS_DST_ALPHA", pure BLEND_FACTOR_ONE_MINUS_DST_ALPHA)
                            , ("BLEND_FACTOR_CONSTANT_COLOR", pure BLEND_FACTOR_CONSTANT_COLOR)
                            , ("BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR", pure BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR)
                            , ("BLEND_FACTOR_CONSTANT_ALPHA", pure BLEND_FACTOR_CONSTANT_ALPHA)
                            , ("BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA", pure BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA)
                            , ("BLEND_FACTOR_SRC_ALPHA_SATURATE", pure BLEND_FACTOR_SRC_ALPHA_SATURATE)
                            , ("BLEND_FACTOR_SRC1_COLOR", pure BLEND_FACTOR_SRC1_COLOR)
                            , ("BLEND_FACTOR_ONE_MINUS_SRC1_COLOR", pure BLEND_FACTOR_ONE_MINUS_SRC1_COLOR)
                            , ("BLEND_FACTOR_SRC1_ALPHA", pure BLEND_FACTOR_SRC1_ALPHA)
                            , ("BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA", pure BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA)]
                     +++
                     prec 10 (do
                       expectP (Ident "BlendFactor")
                       v <- step readPrec
                       pure (BlendFactor v)))

