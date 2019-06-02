{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}

module Write.Cabal
  ( writeCabal
  ) where

import           Control.Arrow                            ((&&&))
import           Data.Either
import           Data.Functor.Extra
import           Data.List.Extra
import           Data.Text                                (Text)
import           Data.Text.Prettyprint.Doc
import           Text.InterpolatedString.Perl6.Unindented

import           Spec.Savvy.Platform
import           Write.Module
import           Write.Util

vulkanVersion :: Doc ()
vulkanVersion = "2.1.0.0"

writeCabal :: [Module] -> [Platform] -> [PlatformGuardInfo] -> Doc ()
writeCabal modules platforms guardInfo =
  let findPlatform n = (pgiPlatform &&& pgiGuard) <$> find ((== n) . pgiModuleName) guardInfo
      (unguardedModules, guardedModules) =
        partitionEithers $ modules <&> \m -> case findPlatform (mName m) of
          Nothing -> Left m
          Just gi -> Right (gi, m)

      guardGroups :: [((Text, Text), [Module])]
      guardGroups =
        fmap (fst . head &&& fmap snd)
          . groupOn fst
          . sortOn fst
          $ guardedModules
  in  [qci|
        -- This file is generated by the 'generate' program in Write.Cabal
        -- Any changes made here will be overwritten when 'generate' is run
        -- again.
        name:                vulkan
        version:             {vulkanVersion}
        synopsis:            Bindings to the Vulkan graphics API.
        description:         Please see readme.md
        homepage:            http://github.com/expipiplus1/vulkan#readme
        license:             BSD3
        license-file:        LICENSE
        author:              Joe Hermaszewski
        maintainer:          live.long.and.prosper@monoid.al
        copyright:           2018 Joe Hermaszewski
        category:            Graphics
        build-type:          Simple
        extra-source-files:  readme.md,
                             changelog.md
        cabal-version:       >=1.10

        {vcat $ writePlatformFlag <$> platforms}

        flag safe-foreign-calls
            description:
              Do not mark foreign imports as 'unsafe'. This means that
              callbacks from Vulkan to Haskell will work. If you are using
              these then make sure this flag is enabled.
            default: False

        library
          hs-source-dirs:      src
          -- We need to use cpphs, as regular cpp ruins latex math with lines
          -- ending in backslashes
          ghc-options:         -Wall -pgmPcpphs -optP--cpp
          build-depends:       cpphs
          exposed-modules:     {indent (-2) . vcat . intercalatePrepend "," $ pretty . mName <$> unguardedModules}

          if flag(safe-foreign-calls)
            cpp-options: -DSAFE_FOREIGN_CALLS

          {indent 0 . vcat $ writeGuardedModules <$> guardGroups}

          build-depends:       base >= 4.9 && < 5
                             , vector-sized >= 0.1 && < 1.1
          default-language:    Haskell2010

          if os(windows)
            extra-libraries:   vulkan-1
          else
            extra-libraries:   vulkan

        source-repository head
          type:     git
          location: https://github.com/expipiplus1/vulkan
  |]

writePlatformFlag :: Platform -> Doc ()
writePlatformFlag platform = [qci|
    flag {pName platform}
        description:
          Enable {pName platform} specific extensions
        -- These are on by default, if lazy-loading or manual dynamic loading
        -- is used then it shouldn't be a problem exposing these.
        default: True
  |]

writeGuardedModules :: ((Text, Text), [Module]) -> Doc ()
writeGuardedModules ((platform, cpp), modules) = [qci|
    if flag({platform})
      cpp-options: -D{cpp}
      exposed-modules: {indent (-2) . vcat . intercalatePrepend "," $ pretty . mName <$> modules}

  |]
