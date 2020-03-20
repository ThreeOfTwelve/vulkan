{-# language AllowAmbiguousTypes #-}
module Render.Peek
  ( peekStmt
  , peekStmtDirect
  , getLenRef
  , storablePeek
  , vectorPeekWithLenRef
  ) where

import           Relude                  hiding ( Type
                                                , ask
                                                , asks
                                                , last
                                                , init
                                                , Const
                                                , Reader
                                                , State
                                                , runReader
                                                )
import qualified Data.Text                     as T
import           Data.Text.Prettyprint.Doc
import           Polysemy
import           Polysemy.NonDet         hiding ( Empty )
import           Polysemy.Fail
import           Data.Vector.Extra              ( pattern (:<|)
                                                , pattern Empty
                                                )
import           Data.Vector                    ( Vector )
import           Polysemy.Reader
import qualified Data.Vector.Extra             as V

import           Foreign.Ptr
import           Foreign.C.Types                ( CChar )
import           Foreign.Storable
import           Foreign.Marshal.Utils
import qualified Data.ByteString               as BS

import           CType                         as C
import           Error
import           Haskell
import           Marshal.Marshalable
import           Marshal.Scheme
import           Render.Element
import           Render.Scheme
import           Render.SpecInfo
import           Render.Stmts
import           Render.Stmts.Poke
import           Render.Type
import           Spec.Types

peekStmt
  :: ( HasErr r
     , Marshalable a
     , Show a
     , HasRenderElem r
     , HasSpecInfo r
     , HasRenderParams r
     , HasSiblingInfo a r
     , HasStmts r
     )
  => a
  -> Ref s AddrDoc
  -> MarshalScheme a
  -> Stmt s r (Maybe (Ref s ValueDoc))
peekStmt a addr scheme = runNonDetMaybe
  $ peekIdiomatic (name a) (lengths a) (Ptr Const (type' a)) addr scheme

peekStmtDirect
  :: ( HasErr r
     , Marshalable a
     , Show a
     , HasRenderElem r
     , HasSpecInfo r
     , HasRenderParams r
     , HasSiblingInfo a r
     , HasStmts r
     )
  => a
  -> Ref s AddrDoc
  -> MarshalScheme a
  -> Stmt s r (Maybe (Ref s ValueDoc))
peekStmtDirect a addr scheme =
  runNonDetMaybe $ peekIdiomatic (name a) (lengths a) (type' a) addr scheme

type Lengths = Vector ParameterLength

peekIdiomatic
  :: ( HasErr r
     , HasRenderElem r
     , HasSpecInfo r
     , HasRenderParams r
     , HasSiblingInfo a r
     , Show a
     , HasStmts r
     )
  => CName
  -> Lengths
  -> CType
  -> Ref s AddrDoc
  -> MarshalScheme a
  -> Sem (NonDet ': StmtE s r ': r) (Ref s ValueDoc)
peekIdiomatic name lengths fromType addr scheme = do
  RenderParams {..} <- ask
  r                 <- peekWrapped name lengths fromType addr scheme
  t                 <- raise $ refType r
  case mkIdiomaticType t of
    Nothing                     -> pure r
    Just (IdiomaticType w _ to) -> raise $ stmtC (Just w) name $ do
      ValueDoc d <- use r
      to <&> \case
        Constructor con ->
          let unwrappedVar = "a"
          in
            Pure AlwaysInline $ ValueDoc
              (   parens
                  (   "\\"
                  <>  parens (con <+> unwrappedVar)
                  <+> "->"
                  <+> unwrappedVar
                  )
              <+> d
              )
        PureFunction fun -> Pure InlineOnce $ ValueDoc (fun <+> d)
        IOFunction   fun -> IOAction $ ValueDoc (fun <+> d)

-- | Render a peek and don't do any unwrapping to idiomatic haskell types
peekWrapped
  :: forall a r s
   . ( HasErr r
     , HasRenderElem r
     , HasSpecInfo r
     , HasRenderParams r
     , HasSiblingInfo a r
     , Show a
     , HasStmts r
     )
  => CName
  -> Lengths
  -> CType
  -> Ref s AddrDoc
  -> MarshalScheme a
  -> Sem (NonDet ': StmtE s r ': r) (Ref s ValueDoc)
peekWrapped name lengths fromType addr = \case
  Normal   toType   -> raise $ normalPeek name addr toType fromType
  Preserve _toType  -> raise $ storablePeek name addr fromType
  ElidedVoid        -> empty
  ElidedLength _ _  -> raise $ storablePeek name addr fromType
  ElidedUnivalued _ -> empty
  ByteString        -> raise $ byteStringPeek @a name lengths addr fromType
  VoidPtr           -> raise $ storablePeek name addr fromType
  Maybe  toType     -> raise $ maybePeek' name lengths addr fromType toType
  Vector toElem     -> raise $ vectorPeek name lengths addr fromType toElem
  Tupled _ toElem   -> raise $ tuplePeek name addr fromType toElem
  EitherWord32 toElem ->
    raise $ eitherWord32Peek name lengths addr fromType toElem
  ElidedCustom CustomSchemeElided {..} ->
    maybe (const empty) (raise .) csePeek addr
  Custom CustomScheme {..} -> raise $ csPeek addr
  s                        -> throw ("Unhandled peek " <> show s)

----------------------------------------------------------------
-- Peeks
----------------------------------------------------------------

storablePeek
  :: forall r a s
   . ( HasErr r
     , HasRenderElem r
     , HasRenderParams r
     , HasSpecInfo r
     , Coercible a (Doc ())
     , Typeable a
     )
  => CName
  -> Ref s AddrDoc
  -> CType
  -> Stmt s r (Ref s a)
storablePeek name addr fromPtr = case fromPtr of
  Ptr _ from -> do
    t <- cToHsType DoLower from
    stmtC @a (Just t) name $ do
      tDoc <- renderTypeHighPrec t
      tellImportWithAll ''Storable
      AddrDoc addrDoc <- use addr
      pure $ IOAction (coerce ("peek @" <> tDoc <+> addrDoc))
  _ -> throw "Trying to generate a storable peek for a non-pointer"

normalPeek
  :: forall r s
   . (HasErr r, HasRenderElem r, HasRenderParams r, HasSpecInfo r)
  => CName
  -> Ref s AddrDoc
  -> CType
  -> CType
  -> Stmt s r (Ref s ValueDoc)
normalPeek name addrRef to fromPtr =
  context (unCName name)
    $   runNonDet (asum [same, inlineStruct, pointerStruct, union])
    >>= \case
          Nothing -> throw
            ("Unhandled " <> show fromPtr <> " conversion to: " <> show to)
          Just ps -> pure ps
 where
  raise2 = raise . raise

  same, inlineStruct, pointerStruct, union
    :: Sem (NonDet ': StmtE s r ': r) (Ref s ValueDoc)

  same = failToNonDet $ do
    Ptr _ from <- pure fromPtr
    guard (from == to)
    case to of
      TypeName n -> do
        guard . isNothing =<< getStruct n
        guard . isNothing =<< getUnion n
      _ -> pure ()
    -- Assume a storable instance...
    raise2 $ storablePeek name addrRef fromPtr

  inlineStruct = failToNonDet $ do
    Ptr _ from@(TypeName n) <- pure fromPtr
    guard (from == to)
    Just s <- getStruct n
    ty     <- cToHsType DoPreserve from
    raise2 $ stmtC (Just ty) name $ do
      tDoc <- renderTypeHighPrec ty
      containsDispatchableHandle s >>= \case
        True -> do
          RenderParams {..} <- ask
          let funName = "peekCStruct" <> unName (mkTyName (sName s))
          tellImport (TermName funName)
          AddrDoc addr <- use addrRef
          CmdsDoc cmds <- useViaName "cmds"
          pure $ IOAction (ValueDoc (pretty funName <+> cmds <+> addr))

        False -> do
          AddrDoc addr <- use addrRef
          tellImportWithAll (TyConName "FromCStruct")
          pure $ IOAction (ValueDoc ("peekCStruct @" <> tDoc <+> addr))

  pointerStruct = failToNonDet $ do
    Ptr _     from         <- pure fromPtr
    Ptr Const (TypeName n) <- pure from
    guard (TypeName n == to)
    Just _ <- getStruct n
    ty     <- cToHsType DoPreserve (TypeName n)
    raise2 $ stmtC (Just ty) name $ do
      tDoc         <- renderTypeHighPrec ty
      AddrDoc addr <- use addrRef
      pure $ IOAction
        (ValueDoc ("peekCStruct @" <> tDoc <+> "=<< peek" <+> addr))

  union = failToNonDet $ do
    Ptr _ from <- pure fromPtr
    TypeName n <- pure from
    Just     u <- getUnion n
    guard (from == to)
    raise2 $ unionPeek name addrRef u to fromPtr

unionPeek
  :: forall r s
   . (HasErr r, HasRenderElem r, HasSpecInfo r, HasRenderParams r)
  => CName
  -> Ref s AddrDoc
  -> Union
  -> CType
  -> CType
  -> Stmt s r (Ref s ValueDoc)
unionPeek name addrRef Struct {..} _to fromPtr =
  failToError (V.singleton . T.pack) $ do
    RenderParams {..} <- ask
    Ptr _ from        <- pure fromPtr
    TypeName n        <- pure from
    ty                <- cToHsType DoPreserve from

    raise $ stmtC (Just ty) name $ do
      discs <- catMaybes <$> sequenceV
        [ useViaNameMaybe (unCName udSiblingName)
        | UnionDiscriminator {..} <- toList unionDiscriminators
        , udUnionType == n
        ]

      ValueDoc discDoc <- case discs of
        []  -> throw ("Unable to find union discriminator for " <> unCName n)
        [d] -> pure d
        _   -> throw ("Found multiple union discriminators for " <> unCName n)

      let peekName = TermName $ "peek" <> unName (mkTyName n)

      AddrDoc addr <- use addrRef
      tellImport peekName
      pure $ IOAction (ValueDoc (pretty peekName <+> discDoc <+> addr))

-- TODO: Check lengths here for null termination
byteStringPeek
  :: forall a r s
   . ( HasErr r
     , HasRenderElem r
     , HasSpecInfo r
     , HasRenderParams r
     , HasSiblingInfo a r
     , Show a
     )
  => CName
  -> Lengths
  -> Ref s AddrDoc
  -> CType
  -> Stmt s r (Ref s ValueDoc)
byteStringPeek name lengths addrRef =
  stmtC (Just (ConT ''ByteString)) name . \case
    Ptr _ (Ptr Const Char) -> do
      AddrDoc addr <- use addrRef
      tellImport 'BS.packCString
      tellImportWithAll ''Storable
      pure . IOAction $ ValueDoc ("packCString =<< peek" <+> addr)

    -- TODO: abstract away this repetition
    Ptr Const Char -> do
      tellImport 'BS.packCString
      AddrDoc addr <- use addrRef
      pure . IOAction $ ValueDoc ("packCString " <+> addr)

    Ptr _ Void | _ :<| V.Empty <- lengths -> do
      lenRef <- getLenRef @a lengths
      tellImport 'BS.packCStringLen
      tellImport 'castPtr
      tellImport ''CChar
      AddrDoc  addr   <- use addrRef
      ValueDoc lenVal <- use lenRef
      let castAddr = "castPtr @() @CChar" <+> addr
      pure . IOAction $ ValueDoc
        ("packCStringLen " <+> tupled [castAddr, lenVal])

    Ptr _ (Array NonConst (SymbolicArraySize _) Char) -> do
      tellImport 'BS.packCString
      tellImport (TermName "lowerArrayPtr")
      AddrDoc addr <- use addrRef
      pure . IOAction $ ValueDoc
        ("packCString" <+> parens ("lowerArrayPtr" <+> addr))

    Ptr _ (Array NonConst (SymbolicArraySize _) (TypeName "uint8_t")) -> do
      let fn = "peekByteStringFromSizedVectorPtr"
      tellImport (TermName fn)
      AddrDoc addr <- use addrRef
      pure . IOAction $ ValueDoc (pretty fn <+> addr)

    t -> throw ("Unhandled conversion to ByteString from " <> show t)

maybePeek'
  :: ( HasErr r
     , HasRenderElem r
     , HasSpecInfo r
     , HasRenderParams r
     , HasSiblingInfo a r
     , Show a
     , HasStmts r
     )
  => CName
  -> Lengths
  -> Ref s AddrDoc
  -> CType
  -> MarshalScheme a
  -> Stmt s r (Ref s ValueDoc)
maybePeek' name lengths addrRef fromPtr to = case fromPtr of
  Ptr _ from@(Ptr _ fromElem) -> do
    let maybePtrDoc   = name
        notNullPtrDoc = "j"
    ptrTy <- cToHsType DoPreserve from

    -- Load the pointer which might be null
    ptr   <- stmtC (Just ptrTy) maybePtrDoc $ do
      AddrDoc addr <- use addrRef
      ptrTDoc      <- renderTypeHighPrec =<< cToHsType DoPreserve from
      tellImportWithAll ''Storable
      pure $ IOAction (AddrDoc ("peek @" <> ptrTDoc <+> addr))

    elemTy <- cToHsType DoPreserve fromElem

    stmtC (Just (ConT ''Maybe :@ elemTy)) name $ do
      AddrDoc ptrDoc <- use ptr
      subPeek        <- renderSubStmtsIO $ do
        ptrRef <- pureStmt (AddrDoc notNullPtrDoc)
        runNonDetMaybe (peekIdiomatic name lengths from ptrRef to) >>= \case
          Nothing -> throw "Nothing to peek to fill Maybe"
          Just p  -> pure p
      tellImport 'maybePeek
      pure
        .   IOAction
        .   ValueDoc
        $   "maybePeek"
        <+> parens ("\\" <> notNullPtrDoc <+> "->" <+> subPeek)
        <+> ptrDoc

  t -> throw ("Unhandled conversion to Maybe from " <> show t)


vectorPeek
  :: forall a r s
   . ( HasErr r
     , HasRenderElem r
     , HasSpecInfo r
     , HasRenderParams r
     , HasSiblingInfo a r
     , Show a
     , HasStmts r
     )
  => CName
  -> Vector ParameterLength
  -> Ref s AddrDoc
  -> CType
  -> MarshalScheme a
  -> Stmt s r (Ref s ValueDoc)
vectorPeek name lengths addrRef fromPtr toElem = case fromPtr of

  Ptr _ (Ptr _ fromElem) | NamedLength _ :<| lenTail <- lengths -> do
    elemPtrRef <- storablePeek name addrRef fromPtr
    lenRef     <- getLenRef @a lengths
    vectorPeekWithLenRef name toElem elemPtrRef fromElem lenTail lenRef

  Ptr _ (Array _ (SymbolicArraySize len) fromElem) -> do
    RenderParams {..} <- ask
    tDoc              <- renderTypeHighPrec =<< cToHsType DoPreserve fromElem

    let lenName = mkPatternName len

    castedAddrRef <- stmt Nothing Nothing $ Pure InlineOnce <$> do
      tellImport (TermName "lowerArrayPtr")
      tellImport lenName
      AddrDoc addr <- use addrRef
      pure . AddrDoc $ "lowerArrayPtr @" <> tDoc <+> addr

    lenRef <- pureStmt (ValueDoc (pretty lenName))
    vectorPeekWithLenRef name toElem castedAddrRef fromElem V.empty lenRef

  -- YUCK, do this initial pointer peeking elsewhere please!
  Ptr _ fromElem | (V.uncons -> Just (_, lenTail)) <- lengths -> do
    lenRef <- getLenRef @a lengths
    vectorPeekWithLenRef name toElem addrRef fromElem lenTail lenRef

  t -> throw ("Unhandled conversion to Vector from " <> show t)

vectorPeekWithLenRef
  :: forall a r s
   . ( HasErr r
     , HasRenderElem r
     , HasSpecInfo r
     , HasRenderParams r
     , HasSiblingInfo a r
     , Show a
     , HasStmts r
     )
  => CName
  -> MarshalScheme a
  -> Ref s AddrDoc
  -> CType
  -> Vector ParameterLength
  -> Ref s ValueDoc
  -> Stmt s r (Ref s ValueDoc)
vectorPeekWithLenRef name toElem addrRef fromElem lenTail lenRef = do
  t <- cToHsType DoPreserve fromElem
  stmtC (Just (ConT ''Vector :@ t)) name $ do
    let indexVar = "i"
    ValueDoc lenDoc <- use lenRef

    -- Render a peeker for the elements
    subPeek         <- renderSubStmtsIO $ do
      -- Get a name for the index variable
      indexRef    <- pureStmt indexVar

      -- Get the value of the pointer to this element
      elemAddrRef <- stmt Nothing Nothing $ do
        (elemSize, _elemAlign) <- getTypeSize fromElem
        indexDoc               <- use indexRef
        -- TODO: be able to coerce refs
        AddrDoc addr           <- raise $ use addrRef

        Pure InlineOnce . AddrDoc <$> do
          tellImport 'plusPtr
          elemPtrTyDoc <-
            renderType . (ConT ''Ptr :@) =<< cToHsType DoPreserve fromElem
          pure $ parens
            (   addr
            <+> "`plusPtr`"
            <+> parens (viaShow elemSize <+> "*" <+> indexDoc)
            <+> "::"
            <+> elemPtrTyDoc
            )

      runNonDetMaybe
          (peekIdiomatic name lenTail (Ptr Const fromElem) elemAddrRef toElem)
        >>= \case
              Nothing -> throw "Nothing to peek to fill Vector"
              Just p  -> pure p

    tellImport 'V.generateM
    pure . IOAction . ValueDoc $ "generateM" <+> lenDoc <+> parens
      ("\\" <> indexVar <+> "->" <+> subPeek)

eitherWord32Peek
  :: forall a r s
   . ( HasErr r
     , HasRenderElem r
     , HasSpecInfo r
     , HasRenderParams r
     , HasSiblingInfo a r
     , Show a
     , HasStmts r
     )
  => CName
  -> Lengths
  -> Ref s AddrDoc
  -> CType
  -> MarshalScheme a
  -> Stmt s r (Ref s ValueDoc)
eitherWord32Peek name lengths addr fromPtr toElem = case fromPtr of
  Ptr _ (Ptr _ fromElem) | (NamedLength len) :<| _ <- lengths -> do
    mRef <-
      note "Unable to get wrapped peek for EitherWord32" =<< runNonDetMaybe
        (peekIdiomatic name lengths fromPtr addr (Maybe (Vector toElem)))
    elemTy <- cToHsType DoPreserve fromElem
    stmtC (Just (ConT ''Either :@ ConT ''Word32 :@ (ConT ''Vector :@ elemTy)))
          name
      . fmap (Pure NeverInline)
      $ do
          ValueDoc lenName <- useViaName (unCName len)
          ValueDoc m       <- use mRef
          pure
            .   ValueDoc
            $   "maybe"
            <+> parens ("Left" <+> lenName)
            <+> "Right"
            <+> m
  t -> throw ("Unhandled conversion to EitherWord32 from " <> show t)

tuplePeek
  :: forall a r s
   . ( HasErr r
     , HasRenderElem r
     , HasSpecInfo r
     , HasRenderParams r
     , HasSiblingInfo a r
     , Show a
     , HasStmts r
     )
  => CName
  -> Ref s AddrDoc
  -> CType
  -> MarshalScheme a
  -> Stmt s r (Ref s ValueDoc)
tuplePeek name addrRef fromPtr toElem = case fromPtr of
  Ptr _ aTy@(Array NonConst (NumericArraySize len) fromElem) -> do
    (elemSize, _elemAlign) <- getTypeSize fromElem

    tupT                   <- cToHsType DoNotPreserve aTy
    stmtC (Just tupT) name $ do

      -- Case the array pointer to a pointer to the first element
      tupPtrRef <-
        stmt Nothing (Just ("p" <> unCName name)) . fmap (Pure InlineOnce) $ do
          tellImport (TermName "lowerArrayPtr")
          tDoc         <- renderTypeHighPrec =<< cToHsType DoPreserve fromElem
          AddrDoc addr <- use addrRef
          pure $ "lowerArrayPtr @" <> tDoc <+> addr

      let
        advance i =
          stmt Nothing Nothing . fmap (Pure InlineOnce . AddrDoc) $ do
            tellImport 'plusPtr
            tupPtrDoc    <- use tupPtrRef
            elemPtrTyDoc <-
              renderType . (ConT ''Ptr :@) =<< cToHsType DoPreserve fromElem
            pure
              (parens
                (   tupPtrDoc
                <+> "`plusPtr`"
                <+> viaShow (elemSize * i)
                <+> "::"
                <+> elemPtrTyDoc
                )
              )

      subPeeks <- forV [0 .. len - 1] $ \i -> do
        elemPtrRef <- advance (fromIntegral i)
        note "Unable to get tuple element peek" =<< runNonDetMaybe
          (peekIdiomatic (CName (unCName name <> show i))
                         mempty
                         (Ptr Const fromElem)
                         elemPtrRef
                         toElem
          )

      Pure InlineOnce . ValueDoc <$> do
        subPeekDocs <- traverseV (fmap unValueDoc . use @r) subPeeks
        pure $ tupled subPeekDocs
  t -> throw ("Unhandled conversion to Tuple from " <> show t)

----------------------------------------------------------------
-- Getting lengths
----------------------------------------------------------------

getLenRef
  :: forall a r s
   . ( HasErr r
     , HasRenderElem r
     , HasRenderParams r
     , HasSpecInfo r
     , HasSiblingInfo a r
     , Show a
     )
  => Lengths
  -> Stmt s r (Ref s ValueDoc)
getLenRef lengths = do
  RenderParams {..} <- ask
  stmt Nothing Nothing $ case lengths of
    Empty                 -> throw "Trying to allocate something with no length"
    NamedLength len :<| _ -> do
      ValueDoc value <- useViaName (unCName len)
      pure . Pure AlwaysInline . ValueDoc $ "fromIntegral" <+> value
    NamedMemberLength struct member :<| _ -> do
      ValueDoc structValue <- useViaName (unCName struct)
      case complexMemberLengthFunction struct member structValue of
        Just complex -> Pure InlineOnce . ValueDoc <$> complex
        Nothing      -> do
          SiblingInfo {..} <- getSiblingInfo @a struct
          structName       <-
            let nonStruct =
                  throw
                    $  "Trying to get length member from a non-struct type "
                    <> show siScheme
            in  case siScheme of
                  Normal (TypeName n) -> getStruct n >>= \case
                    Nothing -> nonStruct
                    Just _  -> pure n
                  _ -> nonStruct
          structTyDoc <-
            renderType
            =<< note
                  "Unable to get type for struct with length specifying member for allocation"
            =<< schemeType siScheme
          tellImportWithAll (mkTyName structName)
          pure
            .   Pure AlwaysInline
            .   ValueDoc
            $   "fromIntegral $"
            <+> pretty (mkMemberName member)
            <+> parens (structValue <+> "::" <+> structTyDoc)
    NullTerminated :<| _ -> throw "Trying to allocate a null terminated"
    -- _ -> throw "Trying to allocate something with multiple lengths"

----------------------------------------------------------------
-- Utils
----------------------------------------------------------------

stmtC
  :: forall a r s
   . (Typeable a, Coercible a (Doc ()))
  => Maybe Type
  -> CName
  -> Stmt s r (Value a)
  -> Stmt s r (Ref s a)
stmtC t n = stmt t (Just (unCName n))
