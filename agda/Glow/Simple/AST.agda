
{-# OPTIONS --cubical  #-}
module Glow.Simple.AST where

open import Agda.Builtin.String
open import Agda.Builtin.Char
-- open import Agda.Builtin.List

open import Cubical.Foundations.Everything 

open import Cubical.Data.Nat
open import Cubical.Data.Int
open import Cubical.Data.Prod
open import Cubical.Data.Sum renaming (elim to sum-elim)
open import Cubical.Data.List renaming (map to map-List)


open import Cubical.Data.Maybe renaming (rec to recMaybe )
open import Cubical.Data.Bool hiding (if_then_else_) renaming (Bool to 𝟚 ; _≟_ to _≟B_)

open import Cubical.Data.Empty renaming (elim to empty-elim ; rec to empty-rec ;  ⊥ to Empty )


-- open import Cubical.Data.Nat.Order.Recursive
-- open import Cubical.Functions.Logic

open import Cubical.Relation.Nullary renaming (¬_ to IsEmpty)
open import Cubical.Relation.Binary

open import Glow.Linked

open import Glow.DecEqMore




isProp-lemma : ∀ {ℓ} → {A B : hProp ℓ} → (a : ⟨ A ⟩ ) → (b : ⟨ B ⟩)
                    →  ⟨ A ⟩ ≡ ⟨ B ⟩
isProp-lemma {A = A} {B} a b = isoToPath (iso (λ _ → b) (λ _ → a) (λ _ → snd B _ _) (λ _ → snd A _ _))

isProp-lemma' :  ∀ {ℓ} → {A B : hProp ℓ} → (a : ⟨ A ⟩ ) → (b : ⟨ B ⟩)
                    → PathP (λ x → ((isProp-lemma {A = A} {B} a b) ∙ refl) x ) a b
isProp-lemma' {A = A} {B = B} a b = compPathP (transport-filler (isProp-lemma {A = A} {B} a b) a ) (snd B _ _)

and-comm  : ∀ x y → x and y ≡ y and x
and-comm false false = refl
and-comm false true = refl
and-comm true false = refl
and-comm true true = refl

and-F  : ∀ x → x and false ≡ false
and-F false = refl
and-F true = refl

F-and  : ∀ x → false and x ≡ false
F-and false = refl
F-and true = refl

and-T  : ∀ x → x and true ≡ x
and-T false = refl
and-T true = refl

T-and  : ∀ x → true and x ≡ x
T-and false = refl
T-and true = refl

and-identityˡ : ∀ x → true and x ≡ x
and-identityˡ false = refl
and-identityˡ true  = refl

and-identityʳ : ∀ x → x and true ≡ x
and-identityʳ false = refl
and-identityʳ true  = refl


pop : ∀ {ℓ} → {A : Type ℓ} → List A → Maybe A 
pop [] = nothing
pop (x ∷ x₁) = just x

tail : ∀ {ℓ} → {A : Type ℓ} → List A → List A 
tail [] = []
tail (_ ∷ xs) = xs

-- infixr 80 •

-- pattern • x = just x

map-List-∘ : ∀ {ℓ} → {A B C : Type ℓ} → (f : A → B) → (g : B → C) → (l : List A) →  map-List g (map-List f l) ≡ map-List (g ∘ f) l 
map-List-∘ f g [] = refl
map-List-∘ f g (x ∷ l) = cong ((g (f x)) ∷_) (map-List-∘ f g l)

-- -- usefull for stratification
-- list-< : \al


data GType : Type₀ where
  Bool : GType 
  Int : GType
  Nat : GType
  Unitᵍ : GType

-- GTy≟ : Discrete GType
-- GTy≟ x y = {!x y!}

GTy== : GType → GType → 𝟚
GTy== Bool Bool = true
GTy== Int Int = true
GTy== Nat Nat = true
GTy== Unitᵍ Unitᵍ = true
GTy== _ _ = false



instance
  IsDiscrete-GType : IsDiscrete GType
  eqTest IsDiscrete-GType Bool Bool = yes refl
  eqTest IsDiscrete-GType Bool Int = no-dec-eq-help' GTy== _
  eqTest IsDiscrete-GType Bool Nat = no-dec-eq-help' GTy== _
  eqTest IsDiscrete-GType Bool Unitᵍ = no-dec-eq-help' GTy== _
  eqTest IsDiscrete-GType Int Bool = no-dec-eq-help' GTy== _
  eqTest IsDiscrete-GType Int Int = yes refl
  eqTest IsDiscrete-GType Int Nat = no-dec-eq-help' GTy== _
  eqTest IsDiscrete-GType Int Unitᵍ = no-dec-eq-help' GTy== _
  eqTest IsDiscrete-GType Nat Bool = no-dec-eq-help' GTy== _
  eqTest IsDiscrete-GType Nat Int = no-dec-eq-help' GTy== _
  eqTest IsDiscrete-GType Nat Nat = yes refl
  eqTest IsDiscrete-GType Nat Unitᵍ = no-dec-eq-help' GTy== _
  eqTest IsDiscrete-GType Unitᵍ Bool = no-dec-eq-help' GTy== _
  eqTest IsDiscrete-GType Unitᵍ Int = no-dec-eq-help' GTy== _
  eqTest IsDiscrete-GType Unitᵍ Nat = no-dec-eq-help' GTy== _
  eqTest IsDiscrete-GType Unitᵍ Unitᵍ = yes refl

GTypeAgdaRep : GType → Type₀
GTypeAgdaRep Bool = 𝟚
GTypeAgdaRep Int = ℤ
GTypeAgdaRep Nat = ℕ
GTypeAgdaRep Unitᵍ = Unit

record IsGlowTy (A : Type₀) : Type₁ where
  field
    glowRep : GType
    glowRep-coh : A ≡ GTypeAgdaRep glowRep
    cast : A → GTypeAgdaRep glowRep

instance
  Bool-IsGlowTy : IsGlowTy 𝟚
  Bool-IsGlowTy = record { glowRep = Bool ; glowRep-coh = refl ; cast = idfun _}

instance
  ℤ-IsGlowTy : IsGlowTy ℤ
  ℤ-IsGlowTy = record { glowRep = Int  ; glowRep-coh = refl ; cast = idfun _ }

instance
  ℕ-IsGlowTy : IsGlowTy ℕ
  ℕ-IsGlowTy = record { glowRep = Nat  ; glowRep-coh = refl ; cast = idfun _ }

instance
  Unit-IsGlowTy : IsGlowTy Unit
  Unit-IsGlowTy = record { glowRep = Unitᵍ  ; glowRep-coh = refl ; cast = idfun _ }


𝟚-elim : ∀ {a} {A : 𝟚 → Type a} → A false → A true → ∀ b → A b
𝟚-elim {a} {A} x x₁ false = x
𝟚-elim {a} {A} x x₁ true = x₁

maybe-elim : ∀ {a} {A : Type a} {B : Maybe A  → Type a} → B nothing → (∀ a → B (just a)) → ∀ x → B x
maybe-elim x x₁ nothing = x
maybe-elim x x₁ (just x₂) = x₁ x₂

ExistMemberAs : ∀ {ℓ ℓ'} → {A : Type ℓ} → (B : A → Type ℓ') → List A → Type ℓ' 
ExistMemberAs B [] = Lift Empty
ExistMemberAs B (x ∷ x₁) = (B x) ⊎ (ExistMemberAs B x₁)



instance
  Dec-Pred-ExistMemberAs : ∀ {ℓ ℓ'} {A : Type ℓ} {B : A → Type ℓ'} {{Dec-Pred-B : Dec-Pred B}}
                                        → Dec-Pred (ExistMemberAs B)
  Dec-Pred-ExistMemberAs = record { decide = h }
     where      
       h : (l : List _) → Dec (ExistMemberAs _ l)
       h [] = no lower
       h (x ∷ xs) = Pred-app ⊎? h xs 

-- this is better encoded like that, than with general rule about turning decidable predicated into propositions, such genreal rule generated tu much
-- unresolved instances resolutions
instance
  Dec-ExistMemberAs : ∀ {ℓ ℓ'} {A : Type ℓ} {B : A → Type ℓ'} {{Dec-Pred-B : Dec-Pred B}}
                                        → {l : List A} → Dec (ExistMemberAs B l)
  Dec-ExistMemberAs {ℓ} {ℓ'} {A} {B} ⦃ Dec-Pred-B ⦄ {l} = Pred-app 


-- Dec-Pred-Dec {{Dec-Pred-ExistMemberAs {{record { predicateDecision = λ _ → ?? _ }}}}}

IsMemberOf : ∀ {ℓ} → {A : Type ℓ} → A → List A → Type ℓ
IsMemberOf a l = ExistMemberAs (a ≡_) l 

ExistFirstBy_WitchIsAlso : ∀ {ℓ ℓ' ℓ''} → {A : Type ℓ} → (B : A → Type ℓ') → (B' : A → Type ℓ'')  → List A → Type (ℓ-max ℓ' ℓ'') 
ExistFirstBy_WitchIsAlso B B' [] = Lift Empty
ExistFirstBy_WitchIsAlso B B' (x ∷ xs) = (B x × B' x) ⊎ ((IsEmpty (B x) × ExistFirstBy_WitchIsAlso B B' xs))


instance
  Dec-Pred-ExistFirstBy_WitchIsAlso : ∀ {ℓ ℓ' ℓ''} → {A : Type ℓ} {B : A → Type ℓ'} {B' : A → Type ℓ''}
                                        {{Dec-Pred-B : Dec-Pred B}} {{Dec-Pred-B' : Dec-Pred B'}}
                                        → Dec-Pred (ExistFirstBy B WitchIsAlso B')
  Dec-Pred-ExistFirstBy_WitchIsAlso = record { decide = h}
     where      
       h : (l : List _) → Dec (ExistFirstBy _ WitchIsAlso _ l)
       h [] = Dec-Empty
       h (x ∷ l) = ×-Dec {{Pred-app}} {{Pred-app}}  ⊎? ×-Dec {{Dec-IsEmpty {{Pred-app}}}} {{h l}}

instance
  Dec-ExistFirstBy_WitchIsAlso : ∀ {ℓ ℓ' ℓ''} → {A : Type ℓ} {B : A → Type ℓ'} {B' : A → Type ℓ''}
                                        {{Dec-Pred-B : Dec-Pred B}} {{Dec-Pred-B' : Dec-Pred B'}} {l : List A}
                                        → Dec (ExistFirstBy B WitchIsAlso B' l)
  Dec-ExistFirstBy_WitchIsAlso  ⦃ Dec-Pred-B ⦄ {l} = Pred-app 


-- postulate ExistFirstBy-WitchIsAlso-preppend-lemma : ∀ {ℓ ℓ' ℓ''} → {A : Type ℓ} → {B : A → Type ℓ'} → {B' : A → Type ℓ''} →
--                                                  (l : List A) → (l' : List A) →
--                                                   ExistFirstBy B WitchIsAlso B' l →
--                                                  (ExistFirstBy B WitchIsAlso B' l ≡ ExistFirstBy B WitchIsAlso B' (l ++ l'))
-- -- ExistFirstBy-WitchIsAlso-preppend-lemma (x₁ ∷ l) l' (inl x) = {!!}
-- -- ExistFirstBy-WitchIsAlso-preppend-lemma (x₁ ∷ l) l' (inr x) = {!!}
--  --cong (_ ⊎_) (cong (_ ×_) ((ExistFirstBy-WitchIsAlso-preppend-lemma l l' {!!})))


ExistFirstBy-WitchIsAlso-preppend-lemma : ∀ {ℓ ℓ' ℓ''} → {A : Type ℓ} → {B : A → Type ℓ'} → {B' : A → Type ℓ''} →
                                                 (l : List A) → (l' : List A) →
                                                  ExistFirstBy B WitchIsAlso B' l →
                                                 (ExistFirstBy B WitchIsAlso B' (l ++ l'))
ExistFirstBy-WitchIsAlso-preppend-lemma (x₁ ∷ l) l' (inl x) = inl x
ExistFirstBy-WitchIsAlso-preppend-lemma (x₁ ∷ l) l' (inr x) =
  inr ((proj₁ x) , (ExistFirstBy-WitchIsAlso-preppend-lemma l l' (proj₂ x)))

-- ExistFirstBy-WitchIsAlso-preppend-lemma' : ∀ {ℓ ℓ' ℓ''} → {A : Type ℓ} → {B : A → Type ℓ'} → {B' : A → Type ℓ''} →
--                                                  (l : List A) → (l' : List A) →
--                                                   ExistFirstBy B WitchIsAlso B' l →
--                                                  (ExistFirstBy B WitchIsAlso B' (l ++ l'))
-- ExistFirstBy-WitchIsAlso-preppend-lemma' (x₁ ∷ l) l' = {!!}



map-ExistingFirstBy_WitchIsAlso : ∀ {ℓ ℓ' ℓ''} → {A : Type ℓ} → (B : A → Type ℓ') → (B' : A → Type ℓ'')
                                          → (l : List A)  → ExistFirstBy B WitchIsAlso B' l → (∀ x → B x → B' x → A) → List A
map-ExistingFirstBy B WitchIsAlso B' (x₂ ∷ l) (inl x₁) f = f x₂ (proj₁ x₁) (proj₂ x₁) ∷ l
map-ExistingFirstBy B WitchIsAlso B' (x₂ ∷ l) (inr x₁) f = map-ExistingFirstBy B WitchIsAlso B' l (proj₂ x₁) f


UniqueBy : ∀ {ℓ ℓ'} → {A : Type ℓ} → (A → A → Type ℓ') → List A → Type ℓ' 
UniqueBy f [] = Lift Unit
UniqueBy f (x ∷ xs) = (IsEmpty (ExistMemberAs (f x) xs)) × UniqueBy f xs

UniqueByDec≡  : ∀ {ℓ ℓ'} → {A : Type ℓ} → {A' : Type ℓ'} → (f : A → A') → {{IsDiscrete A'}} → ∀ l → Dec (UniqueBy {A = A} (λ x x₁ → f x ≡ f x₁) l) 
UniqueByDec≡ _ [] = yes _
UniqueByDec≡ _ (x ∷ xs) = ×-Dec {{Dec-B = UniqueByDec≡ _ xs }}

FilterOut : ∀ {ℓ ℓ'} → {A : Type ℓ} (B : A → Type ℓ') {{Dec-Pred-B : Dec-Pred B}}
                → List A → Σ (List A) λ l → IsEmpty (ExistMemberAs B l)
FilterOut _ ⦃ Dec-Pred-B = Dec-Pred-B ⦄ [] = [] , lower
FilterOut B ⦃ Dec-Pred-B = Dec-Pred-B ⦄ (x ∷ x₁) =
   let q = FilterOut B x₁
   in dec-rec _ {{Dec-Pred.decide Dec-Pred-B x}}
        (λ _ → q) λ y → x ∷ fst q , sum-elim y (snd q)


-- TODD : decision procedure


Empty⊎ : ∀ {ℓ ℓ'} → {A : Type ℓ} → {B : Type ℓ'} → (IsEmpty A) → A ⊎ B → B
Empty⊎ x (inl x₁) = empty-elim (x x₁)
Empty⊎ x (inr x₁) = x₁

module AST (Identifier : Type₀) {{IsDiscrete-Identifier : IsDiscrete Identifier}} where 



 

  record IdentifierWithType : Type₀ where
    pattern
    constructor iwt
    field
      name : Identifier
      type : GType

  open IdentifierWithType

  instance
    IdentifierWithType-Discrete : IsDiscrete IdentifierWithType
    eqTest IdentifierWithType-Discrete x y =
      dec-rec ((x .name ≡ y .name) × (x .type ≡ y .type))
               
        (λ x₁ → yes λ i → iwt (proj₁ x₁ i) (proj₂ x₁ i)) λ x₁ → no λ x₂ → x₁ ((λ i → name (x₂ i)) , (λ i → (type (x₂ i))))


  ParametersValue : List IdentifierWithType →  Type₀
  ParametersValue [] = Unit
  ParametersValue (x ∷ xs) = GTypeAgdaRep (type x) × ParametersValue xs

  lookup-ParametersValue : (l : List IdentifierWithType) → ParametersValue l
                             → (x : IdentifierWithType)
                             → IsMemberOf x l 
                             → GTypeAgdaRep (type x)
  lookup-ParametersValue (x₃ ∷ l) (x₁ , x₂) x ex =
     dec-rec (x ≡ x₃)
        (λ p → subst (GTypeAgdaRep) (cong type (sym p)) x₁)
        (λ ¬p → lookup-ParametersValue l x₂ x (Empty⊎ ¬p ex))

  IsParticipantId : {participants : List Identifier} → Identifier → Σ _ Dec
  IsParticipantId {participants} name =
      ExistMemberAs (name ≡_) participants
        , ?? _

  data ParticipantId' {participants : List Identifier} : Type₀ where
    pId : (name : Identifier) → {isIn :  True (snd (IsParticipantId {participants} name))} → ParticipantId'

  pId-name : ∀ {ptps} → ParticipantId' {ptps} → Identifier
  pId-name (pId name₁) = name₁

  -- record ParticipantId' {participants : List Identifier} : Type₀ where
  --   constructor pId
    
  --   field
  --     name : Identifier
  --     {isIn} : True (snd (IsParticipantId {participants} name))

  open ParticipantId' public


  Scope' : {participants : List Identifier} → Type₀
  Scope' {participants} = Maybe (ParticipantId' {participants})

  _CanAccess_ : ∀ {ps} → Scope' {ps} → Scope' {ps} → Σ _ Dec
  _ CanAccess nothing = Unit , ?? _
  just x CanAccess just x₁ = ((pId-name x) ≡ (pId-name x₁)) , ?? _
  nothing CanAccess just x₁ = Empty , ?? _

  AllowedScopeNarrowing' : ∀ {ps} → Scope' {ps} → Scope' {ps} → Σ _ Dec
  AllowedScopeNarrowing' s nothing = Unit , yes _
  AllowedScopeNarrowing' s (just x) = caseMaybe (Unit , yes _) (Empty , no (idfun _)) s



  record ContextEntry' {participants : List Identifier} : Type₀ where
    constructor ice

    field
      scope : Scope' {participants}
      name : Identifier
      type : GType




  open ContextEntry' public



  record InteractionHead : Type₀ where
    constructor interactionHead
    -- inductive
    pattern
    field
      participants : List Identifier
      parameters : List IdentifierWithType
      {uniqueParams} : True (UniqueByDec≡ name parameters)





    ParticipantId : Type₀
    ParticipantId = ParticipantId' {participants}


    Scope : Type₀
    Scope = Maybe ParticipantId

    ContextEntry = ContextEntry' {participants}

    AType : ContextEntry → Type₀
    AType ce = GTypeAgdaRep (ce .type)

    ce-name : ContextEntry → Identifier
    ce-name = ContextEntry'.name

    record Context : Type₀ where
      pattern
      constructor con


      field
        entries : List ContextEntry

      field
        scope' : Scope

      

      IsDefinedVariableOfTy : GType → Identifier → Σ _ Dec
      IsDefinedVariableOfTy ty x =
        ExistFirstBy ((x ≡_) ∘ name) 
           WitchIsAlso (λ y → ⟨ scope' CanAccess (scope y) ⟩ × (ty ≡ type y) ) entries
         , Dec-ExistFirstBy_WitchIsAlso {{Dec-Pred-B' = dec-pred λ y → ×-Dec {{snd (scope' CanAccess (scope y))}}}}

      IsNotShadowedParamOfTy : GType → Identifier → Type ℓ-zero
      IsNotShadowedParamOfTy ty x =
         IsEmpty (ExistMemberAs ((x ≡_) ∘ name) entries)
            × IsMemberOf (iwt x ty) parameters      
                 

      IsDefinedSymbolOfTy : GType → Identifier → Σ _ Dec
      IsDefinedSymbolOfTy ty x =
        ⟨ IsDefinedVariableOfTy ty x ⟩ ⊎ IsNotShadowedParamOfTy ty x ,
          ⊎-Dec {{snd (IsDefinedVariableOfTy ty x) }}


      data DefinedSymbolOfTy (Τ : GType) : Type ℓ-zero where
        dsot : (name : Identifier) → {isDefinedSymbolOfTy : True (snd( IsDefinedSymbolOfTy Τ name))} → DefinedSymbolOfTy Τ

      open DefinedSymbolOfTy public


      IsPrivateSymbolOf : ParticipantId → Identifier → Σ _ Dec
      IsPrivateSymbolOf p x =
         ExistFirstBy ((x ≡_) ∘ name)
            WitchIsAlso (λ y → recMaybe Empty (λ p' → (pId-name p) ≡ (pId-name p')) (scope y)) entries
           , Dec-ExistFirstBy_WitchIsAlso {{Dec-Pred-B' = Dec-Pred-Maybe {f = scope}}} 


      data PrivateSymbolOf (p : ParticipantId) : Type ℓ-zero where
        psof : (name : Identifier) → {isDefinedSymbolOf : True ( snd ( IsPrivateSymbolOf p name ))} → PrivateSymbolOf p 

      psof-name : ∀ {p} → PrivateSymbolOf p → Identifier
      psof-name (psof x) = x 

      psof-proof : ∀ {p} → (pso : PrivateSymbolOf p) → True ( snd ( IsPrivateSymbolOf p (psof-name pso) ))
      psof-proof (psof x {y}) = y 



      open PrivateSymbolOf public



      IsConsensus : Σ _ Dec
      IsConsensus = caseMaybe (Unit , yes _) (Empty , no (idfun _)) scope'

      IsNotConsensus : Σ _ Dec
      IsNotConsensus = caseMaybe (Empty , no (idfun _)) (Unit , yes _)  scope'


    open Context public

    -- context-< : Context → ℕ → Type₀ 
    -- context-< x x₁ = {!!}

    emptyContext : Context
    emptyContext = con [] nothing

    prependContext : ContextEntry → Context →  Context
    prependContext x Γ = record Γ { entries =   Γ .entries ∷ʳ x } 

    addToContext : Context → ContextEntry → Context
    addToContext Γ x = record Γ { entries =  x ∷ Γ .entries } 


    removeFromContext' : ∀ (Γ : _) → ∀ s → ∀ Τ → ⟨ IsDefinedVariableOfTy Γ Τ s ⟩ → List ContextEntry
    removeFromContext' (con (x₁ ∷ entries₁) scope'') s Τ (inl x) = entries₁
    removeFromContext' (con (x₁ ∷ entries₁) scope'') s Τ (inr x) =  (x₁ ∷ removeFromContext' (con (entries₁) scope'') s Τ (proj₂ x) )

    removeFromContext : ∀ (Γ : _) → ∀ s → ∀ Τ → ⟨ IsDefinedVariableOfTy Γ Τ s ⟩ → Context
    removeFromContext Γ s Τ x = record Γ { entries =  removeFromContext' Γ s Τ x } 


    AllowedScopeNarrowing : (Γ : Context) → Scope → Σ _ Dec
    AllowedScopeNarrowing Γ = AllowedScopeNarrowing' (scope' Γ) 


    narrowScope : (Γ : Context) → (s : Scope)  → .(True (snd ( AllowedScopeNarrowing Γ s))) → Scope
    narrowScope Γ s _ = caseMaybe s (scope' Γ) (Γ .scope') 

    narrow : (Γ : Context) → (s : Scope)  → .(True (snd (AllowedScopeNarrowing Γ s) )) → Context
    narrow Γ a x = record Γ { scope' = narrowScope Γ a x }




    data Stmnt (Γ : Context) : Type₀

    data BStmnt (Γ : Context) : Type₀


    data NBStmnt (Γ : Context) : Type₀

    data NBStmnt+Expr (Γ : Context) : Type₀

    data Expr (Γ : Context) (Τ : GType): Type₀

    bindingMechanics : {Γ : Context} → BStmnt Γ → List ContextEntry 

    bindingMechanics' : (Γ : Context) → Stmnt Γ → Context 


    record Body (Γ : _) (Τ : _ ) : Type₀ where
      pattern
      inductive
      constructor bodyR
      field
        stmnts : Linked' bindingMechanics' Γ
        expr : Expr (foldLinked' stmnts) Τ

    open Body public




    data Expr Γ Τ where
      var : DefinedSymbolOfTy Γ Τ → Expr Γ Τ
      body : Body Γ Τ → Expr Γ Τ
      lit : GTypeAgdaRep Τ → Expr Γ Τ
      input : String → {_ : True (snd (IsNotConsensus Γ)) } → Expr Γ Τ
      if_then_else_ : Expr Γ Bool → Expr Γ Τ → Expr Γ Τ → Expr Γ Τ

    data Stmnt Γ where
      -- not necessary binding, but rather context changing
      bindingS : BStmnt Γ → Stmnt Γ
      nonBindingS : NBStmnt+Expr Γ → Stmnt Γ

    data BStmnt Γ where
                    -- warning: scope in "ce" is interpreted in unusual way!
                    -- (TODO : consider speical type here)
      BS-let : (ce : ContextEntry) → {asn : True (snd (AllowedScopeNarrowing Γ (scope ce)) )}
                  → Expr (narrow Γ (scope ce) asn) (type ce) → BStmnt Γ    
      BS-publish! : (p : ParticipantId) → (PrivateSymbolOf Γ p)
                             → {_ : True (snd( IsConsensus Γ )) }→  BStmnt Γ
      -- verify! ‹ids›

    data NBStmnt Γ where
      NBS-require! : Expr Γ Bool → NBStmnt Γ
      NBS-deposit! : ParticipantId → {_ : True (snd( IsConsensus Γ )) } → Expr Γ Nat → NBStmnt Γ
      NBS-withdraw! : ParticipantId → {_ : True (snd( IsConsensus Γ )) } → Expr Γ Nat → NBStmnt Γ


    data NBStmnt+Expr Γ where
      stmntNBS : NBStmnt Γ → NBStmnt+Expr Γ
      exprNBS : ∀ {Τ} → Expr Γ Τ → NBStmnt+Expr Γ

    bindingMechanics {Γ} (BS-let ce _) = ce ∷ Γ .entries
    bindingMechanics {Γ} (BS-publish! p x) = 
      map-ExistingFirstBy _ WitchIsAlso _ (Γ .entries) (toWitness (psof-proof _ x)) 
         λ e _ _ → record e { scope = nothing }  

    bindingMechanics' Γ (bindingS x) = record Γ { entries =  bindingMechanics x } 
    bindingMechanics' Γ (nonBindingS x) = Γ

    Statements : Context → Type₀
    Statements Γ = Linked' bindingMechanics' Γ

    -- Expr-eq? : ∀ Γ Τ → (x y : Expr Γ Τ) → Dec (x ≡ y) 
    -- Expr-eq? Γ Τ (var (dsot x {x'})) (var (dsot y {y'})) = 
    --   dec-rec (x ≡ y)
    --     (λ p →   let q = True-Pa {A = λ i₁ → (fst (IsDefinedSymbolOfTy Γ Τ (p i₁)))} {(λ i₁ → (snd (IsDefinedSymbolOfTy Γ Τ (p i₁))))} {x'} {y'}
    --              in yes λ i → (var (dsot (p i) {{!!}})))
    --     {!!} 

    -- Expr-eq? Γ Τ (var x) (body x₁) = {!!}
    -- Expr-eq? Γ Τ (var x) (lit x₁) = {!!}
    -- Expr-eq? Γ Τ (body x) (var x₁) = {!!}
    -- Expr-eq? Γ Τ (body x) (body x₁) = {!!}
    -- Expr-eq? Γ Τ (body x) (lit x₁) = {!!}
    -- Expr-eq? Γ Τ (lit x) (var x₁) = {!!}
    -- Expr-eq? Γ Τ (lit x) (body x₁) = {!!}
    -- Expr-eq? Γ Τ (lit x) (lit x₁) = {!!}



  toParamValue : ∀ (l : List IdentifierWithType)  → ParametersValue l →
                 ∀ Τ s → 
                 IsMemberOf (iwt s Τ) l →
                 GTypeAgdaRep Τ
  toParamValue (x₂ ∷ l) (x , xs) Τ s (inl p) = subst (GTypeAgdaRep) (cong type (sym p)) x
  toParamValue (x₂ ∷ l) (x , xs) Τ s (inr x₁) = (toParamValue l xs Τ s x₁)



  record Interaction : Type₀ where
    pattern
    constructor interaction
    field
      head : InteractionHead

    open InteractionHead head public

    field
      code : Linked' bindingMechanics' emptyContext 

  open InteractionHead public

  infixl 6 interaction⟨_,_⟩_
  infixr 50 _∶_ 

  infixr 10 _;b_
  infixr 15 _;_
  infix 17 _;₁
  infixr 15 _;'_

  infix 30 set_∶_≔_
  infix 30 at_set_∶_≔_


  infix 60 <_>

  pattern interaction⟨_,_⟩_ prts prms stmnts = interaction (interactionHead prts prms ) stmnts

  pattern _∶_ x y = iwt x y 

  pattern _;_ x y = _∷L_ x y


  pattern _;₁ x = x ; []L  

  pattern _;'_ x y = x ; y ;₁  

  pattern set_∶_≔_ x y z =
    bindingS (BS-let (ice nothing x y) z)

  pattern at_set_∶_≔_ p x y z =
    bindingS
       (BS-let (ice (just (pId p)) x y) z)

  pattern publish!_⟶_ x y = bindingS (BS-publish! (pId x) (psof y))

  pattern deposit!_⟶_ x y = nonBindingS (stmntNBS (NBS-deposit! (pId x) y))

  pattern withdraw!_⟵_ x y = nonBindingS (stmntNBS (NBS-withdraw! (pId x) y))

  pattern require!_ x = nonBindingS (stmntNBS (NBS-require! x))


  <_> : ∀ {IH Γ} → {A : Type₀} → ⦃ isGlowTy : IsGlowTy A ⦄ →
           A →  Expr IH Γ (IsGlowTy.glowRep isGlowTy)
  <_> {IH} {Γ} {A} ⦃ isGlowTy ⦄ x = lit (IsGlowTy.cast isGlowTy x)

  pattern _;b_ x y = body (bodyR x y)  

  infixr 60 v_

  pattern v_ x = var (dsot x)

-- open AST String {{String-Discrete-postulated}}

-- someInteraction : Interaction
-- someInteraction =  
--    interaction⟨   "A" ∷ "B" ∷ [] ,  "pI1" ∶ Nat ∷ "b2" ∶ Bool ∷ "b1" ∶ Bool ∷ [] ⟩ (
--         set "x" ∶ Bool ≔ < true > ;
--         at "B" set "y" ∶ Bool ≔ v "b1" ;
--         at "A" set "xx" ∶ Bool ≔
--          ( if v "b1"
--            then
--               (
--               set "z" ∶ Bool ≔ input "enter choice 1" ;₁ ;b
--               v "z"
--             )
--            else (
--             require! v "b2" ;'
--             -- publish! "B" ⟶ "y" ;
--             -- withdraw! "B" ⟵ < 3 > ;
--             -- deposit! "B" ⟶ < 2 > ;
--             set "z" ∶ Bool ≔ < false > ;b
--             < true >
--             )) ;
--         deposit! "B" ⟶ < 2 > ;
--         at "A" set "yq" ∶ Bool ≔ input "enter choice 2" ;
--         withdraw! "B" ⟵ < 3 > ;
--         publish! "A" ⟶ "xx" ;        

--         publish! "B" ⟶ "y" ;'        
--         set "yy" ∶ Bool ≔ v "y" )
