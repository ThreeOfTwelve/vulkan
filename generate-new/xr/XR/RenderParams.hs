module XR.RenderParams
  ( renderParams
  ) where

import qualified Bespoke.RenderParams          as Vk
import           CType
import           Data.Char                      ( isLower )
import           Data.Generics.Uniplate.Data
import qualified Data.HashSet                  as Set
import qualified Data.List                     as List
import qualified Data.Text                     as T
import           Data.Text.Extra                ( lowerCaseFirst
                                                , upperCaseFirst
                                                )
import           Data.Text.Extra               as T
                                                ( (<+>) )
import           Data.Text.Prettyprint.Doc      ( pretty )
import           Data.Vector                    ( Vector )
import           Foreign.Ptr
import           Haskell
import           Language.Haskell.TH
import           Polysemy
import           Relude                  hiding ( Handle
                                                , Type
                                                , uncons
                                                )
import           Render.Element
import           Render.Stmts                   ( useViaName )
import           Render.Stmts.Poke              ( CmdsDoc(..) )
import           Render.Type.Preserve
import           Spec.Parse
import           Text.Casing             hiding ( dropPrefix )
import           VkModulePrefix

renderParams :: Vector Handle -> RenderParams
renderParams handles = r
 where
  dispatchableHandleNames = Set.fromList
    [ hName | Handle {..} <- toList handles, hDispatchable == Dispatchable ]
  vulkanParams = Vk.renderParams handles
  r            = RenderParams
    { mkTyName = \n -> TyConName $ fromMaybe (upperCaseFirst . dropXr $ n)
                                             (vulkanNameOverrides n)
    , mkConName = \_ n -> ConName $ fromMaybe (upperCaseFirst . dropXr $ n)
                                              (vulkanNameOverrides n)
    , mkMemberName                   = \_parent ->
                                         TermName . lowerCaseFirst . dropPointer . unCName
    , mkFunName                      = TermName . lowerCaseFirst . dropXr
    , mkParamName                    = TermName . dropPointer . unCName
    , mkPatternName                  =
      \n -> ConName
        $ fromMaybe (upperCaseFirst . dropXr $ n) (vulkanNameOverrides n)
    , mkFuncPointerName              = TyConName . T.tail . unCName
    , mkFuncPointerMemberName = TermName . ("p" <>) . upperCaseFirst . unCName
    , mkEmptyDataName                = TyConName . (<> "_T") . dropXr
    , mkDispatchableHandlePtrName    = TermName
                                       . (<> "Handle")
                                       . lowerCaseFirst
                                       . dropXr
    , camelPrefix                    = "Xr"
    , lowerPrefix                    = "xr"
    , upperPrefix                    = "XR"
    , flagsTypeName                  = "XrFlags64"
    , alwaysQualifiedNames           = mempty
    , mkIdiomaticType                =
      let
        dropVulkanModule = transformBi
          (\n -> if nameModule n == Just (T.unpack vulkanModulePrefix)
            then mkName (nameBase n)
            else n
          )
        xrIdiomatic =
          (`List.lookup` (  [ ( ConT (typeName $ mkTyName r "XrBool32")
                              , IdiomaticType
                                (ConT ''Bool)
                                (do
                                  tellImport (TermName "boolToBool32")
                                  pure "boolToBool32"
                                )
                                (do
                                  tellImport (TermName "bool32ToBool")
                                  pure $ PureFunction "bool32ToBool"
                                )
                              )
                            ]
                         <> [ ( ConT ''Ptr
                                :@ ConT (typeName $ mkEmptyDataName r name)
                              , IdiomaticType
                                (ConT (typeName $ mkTyName r name))
                                (do
                                  let h = mkDispatchableHandlePtrName r name
                                  tellImportWithAll (mkTyName r name)
                                  pure (pretty h)
                                )
                                (do
                                  let c = mkConName r name name
                                  tellImportWith (mkTyName r name) c
                                  case name of
                                    "XrInstance" -> do
                                      tellImport (TermName "initInstanceCmds")
                                      pure
                                        .   IOFunction
                                        $   "(\\h ->"
                                        <+> pretty c
                                        <+> "h <$> initInstanceCmds h)"
                                    _ -> do
                                      CmdsDoc cmds <- useViaName "cmds"
                                      pure
                                        .   PureFunction
                                        $   "(\\h ->"
                                        <+> pretty c
                                        <+> "h"
                                        <+> cmds
                                        <+> ")"
                                )
                              )
                            | name <- toList dispatchableHandleNames
                            ]
                         )
          )
      in
        \t ->
          xrIdiomatic t
            <|> (mkIdiomaticType vulkanParams . dropVulkanModule $ t)
    , mkHsTypeOverride = \_ preserve t -> pure <$> case preserve of
      DoNotPreserve -> Nothing
      _             -> case t of
        TypeName n | Set.member n dispatchableHandleNames ->
          Just $ ConT ''Ptr :@ ConT (typeName (mkEmptyDataName r n))
        _ -> Nothing
    , unionDiscriminators            = mempty
    , successCodeType                = TypeName "XrResult"
    , isSuccessCodeReturned          = (/= "XR_SUCCESS")
    , firstSuccessCode               = "XR_SUCCESS"
    , exceptionTypeName              = TyConName "OpenXrException"
    , complexMemberLengthFunction    = \_ _ _ -> Nothing
    , isExternalName                 = const Nothing
    , externalDocHTML                = Just
      "https://www.khronos.org/registry/OpenXR/specs/1.0/html/xrspec.html"
    , objectTypePattern              = pure
                                       . mkPatternName r
                                       . CName
                                       . ("XR_OBJECT_TYPE_" <>)
                                       . T.pack
                                       . toScreamingSnake
                                       . fromHumps
                                       . T.unpack
                                       . dropXr
    , extensibleStructTypeMemberName = Just "type"
    , extensibleStructTypeType       = Just "XrStructureType"
    }

dropXr :: CName -> Text
dropXr (CName t) = fromMaybe t (dropPrefix "xr" t)

-- TODO: expand or remove
vulkanNameOverrides :: CName -> Maybe Text
vulkanNameOverrides = \case
  _ -> Nothing

dropPrefix
  :: Text
  -- ^ Prefix
  -> Text
  -- ^ body
  -> Maybe Text
  -- ^ Nothing if 'body' didn't begin with 'prefix'
dropPrefix p t = if p `T.isPrefixOf` T.toLower t
  then Just . T.dropWhile (== '_') . T.drop (T.length p) $ t
  else Nothing

dropPointer :: Text -> Text
dropPointer =
  lowerCaseFirst
    . uncurry (<>)
    . first (\p -> if T.all (== 'p') p then "" else p)
    . T.span isLower

-- TODO: Generate this automatically
vulkanManifest
  :: ExtensibleStructStyle r -> RenderParams -> CType -> Maybe (Sem r Type)
vulkanManifest structStyle RenderParams {..} =
  let vk =
        Just
          . pure
          . ConT
          . mkName
          . T.unpack
          . ((vulkanModulePrefix <> ".") <>)
          . unName
          . mkTyName
      someVk t = Just $ do
        let structTyCon =
              ConT
                . mkName
                . T.unpack
                . ((vulkanModulePrefix <> ".") <>)
                . unName
                . mkTyName
                $ t
        case structStyle of
          Applied getVar -> do
            v <- getVar
            pure $ structTyCon :@ v
          Wrapped -> pure $ ConT (mkName "SomeStruct") :@ structTyCon
  in  \case
        TypeName n
          | n
            `elem` [ "VkFlags"
                   , "VkAllocation"
                   , "VkAllocationCallbacks"
                   , "VkBool32"
                   , "VkCommandBuffer_T"
                   , "VkDeviceMemory"
                   , "VkDeviceSize"
                   , "VkDevice_T"
                   , "VkInstance_T"
                   , "VkMemoryPropertyFlags"
                   , "VkPhysicalDevice_T"
                   , "VkBuffer"
                   , "VkBufferCopy"
                   , "VkBufferMemoryRequirementsInfo2"
                   , "VkImage"
                   , "VkMappedMemoryRange"
                   , "VkMemoryMapFlags"
                   , "VkMemoryRequirements"
                   , "VkPhysicalDeviceMemoryProperties"
                   , "VkPhysicalDeviceProperties"
                   , "VkResult"
                   ]
          -> vk n
          | n
            `elem` [ "VkMemoryAllocateInfo"
                   , "VkBindBufferMemoryInfo"
                   , "VkBindImageMemoryInfo"
                   , "VkBufferCreateInfo"
                   , "VkImageCreateInfo"
                   , "VkMemoryRequirements2"
                   , "VkImageMemoryRequirementsInfo2"
                   , "VkPhysicalDeviceMemoryProperties2"
                   ]
          -> someVk n
        _ -> Nothing

