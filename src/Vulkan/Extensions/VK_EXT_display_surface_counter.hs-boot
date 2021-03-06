{-# language CPP #-}
module Vulkan.Extensions.VK_EXT_display_surface_counter  ( SurfaceCapabilities2EXT
                                                         , SurfaceCounterFlagBitsEXT
                                                         , SurfaceCounterFlagsEXT
                                                         ) where

import Data.Kind (Type)
import Vulkan.CStruct (FromCStruct)
import Vulkan.CStruct (ToCStruct)
data SurfaceCapabilities2EXT

instance ToCStruct SurfaceCapabilities2EXT
instance Show SurfaceCapabilities2EXT

instance FromCStruct SurfaceCapabilities2EXT


data SurfaceCounterFlagBitsEXT

type SurfaceCounterFlagsEXT = SurfaceCounterFlagBitsEXT

