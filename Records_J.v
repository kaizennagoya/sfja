(** * Records: Adding Records to STLC *)

(* $Date: 2011-03-21 13:05:05 -0400 (Mon, 21 Mar 2011) $ *)

Require Export Stlc_J.
Require Import Relations.

(* ###################################################################### *)
(** * Adding Records *)

(** We saw in [MoreStlc.v] how records can be treated as syntactic
    sugar for nested uses of products.  This is fine for simple
    examples, but the encoding is informal (in reality, if we really
    treated records this way, it would be carried out in the parser,
    which we are eliding here), and anyway it is not very efficient.
    So it is also interesting to see how records can be treated as
    first-class citizens of the language.

    Recall the informal definitions we gave before: *)

(**
    Syntax:
<<
       t ::=                          Terms:
           | ...
           | {i1=t1, ..., in=tn}         record
           | t.i                         projection

       v ::=                          Values:
           | ...
           | {i1=v1, ..., in=vn}         record value

       T ::=                          Types:
           | ...
           | {i1:T1, ..., in:Tn}         record type
>>
   Reduction:
[[[
                                 ti ==> ti'                            (ST_Rcd)
    --------------------------------------------------------------------
    {i1=v1, ..., im=vm, in=tn, ...} ==> {i1=v1, ..., im=vm, in=tn', ...}

                                 t1 ==> t1'
                               --------------                        (ST_Proj1)
                               t1.i ==> t1'.i

                          -------------------------                (ST_ProjRcd)
                          {..., i=vi, ...}.i ==> vi
]]]
   Typing:
[[[
               Gamma |- t1 : T1     ...     Gamma |- tn : Tn
             --------------------------------------------------         (T_Rcd)
             Gamma |- {i1=t1, ..., in=tn} : {i1:T1, ..., in:Tn}

                       Gamma |- t : {..., i:Ti, ...}
                       -----------------------------                   (T_Proj)
                             Gamma |- t.i : Ti
]]]
*)

(* ###################################################################### *)
(** * Formalizing Records *)

Module STLCExtendedRecords.

(* ###################################################################### *)
(** *** Syntax and Operational Semantics *)

(** The most obvious way to formalize the syntax of record types would
    be this: *)

Module FirstTry.

Definition alist (X : Type) := list (id * X).

Inductive ty : Type :=
  | ty_base     : id -> ty
  | ty_arrow    : ty -> ty -> ty
  | ty_rcd      : (alist ty) -> ty.

(** Unfortunately, we encounter here a limitation in Coq: this type
    does not automatically give us the induction principle we expect
    -- the induction hypothesis in the [ty_rcd] case doesn't give us
    any information about the [ty] elements of the list, making it
    useless for the proofs we want to do.  *)

(* Check ty_ind.
   ====>
    ty_ind :
      forall P : ty -> Prop,
        (forall i : id, P (ty_base i)) ->
        (forall t : ty, P t -> forall t0 : ty, P t0 -> P (ty_arrow t t0)) ->
        (forall a : alist ty, P (ty_rcd a)) ->    (* ??? *)
        forall t : ty, P t
*)

End FirstTry.

(** It is possible to get a better induction principle out of Coq, but
    the details of how this is done are not very pretty, and it is not
    as intuitive to use as the ones Coq generates automatically for
    simple [Inductive] definitions.

    Fortunately, there is a different way of formalizing records that
    is, in some ways, even simpler and more natural: instead of using
    the existing [list] type, we can essentially include its
    constructors ("nil" and "cons") in the syntax of types. *)

Inductive ty : Type :=
  | ty_base : id -> ty
  | ty_arrow : ty -> ty -> ty
  | ty_rnil : ty
  | ty_rcons : id -> ty -> ty -> ty.

Tactic Notation "ty_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "ty_base" | Case_aux c "ty_arrow"
  | Case_aux c "ty_rnil" | Case_aux c "ty_rcons" ].

(** Similarly, at the level of terms, we have constructors [tm_rnil]
    -- the empty record -- and [tm_rcons], which adds a single field to
    the front of a list of fields. *)

Inductive tm : Type :=
  | tm_var : id -> tm
  | tm_app : tm -> tm -> tm
  | tm_abs : id -> ty -> tm -> tm
  (* records *)
  | tm_proj : tm -> id -> tm
  | tm_rnil :  tm
  | tm_rcons : id -> tm -> tm -> tm.

Tactic Notation "tm_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "tm_var" | Case_aux c "tm_app" | Case_aux c "tm_abs"
  | Case_aux c "tm_proj" | Case_aux c "tm_rnil" | Case_aux c "tm_rcons" ].

(** Some variables, for examples... *)

Notation a := (Id 0).
Notation f := (Id 1).
Notation g := (Id 2).
Notation l := (Id 3).
Notation A := (ty_base (Id 4)).
Notation B := (ty_base (Id 5)).
Notation k := (Id 6).
Notation i1 := (Id 7).
Notation i2 := (Id 8).

(** [{ i1:A }] *)

(* Check (ty_rcons i1 A ty_rnil). *)

(** [{ i1:A->B, i2:A }] *)

(* Check (ty_rcons i1 (ty_arrow A B)
           (ty_rcons i2 A ty_rnil)). *)

(* ###################################################################### *)
(** *** Well-Formedness *)

(** Generalizing our abstract syntax for records (from lists to the
    nil/cons presentation) introduces the possibility of writing
    strange types like this *)

Definition weird_type := ty_rcons X A B.

(** where the "tail" of a record type is not actually a record type! *)

(** We'll structure our typing judgement so that no ill-formed types
    like [weird_type] are assigned to terms.  To support this, we
    define [record_ty] and [record_tm], which identify record types
    and terms, and [well_formed_ty] which rules out the ill-formed
    types. *)

(** First, a type is a record type if it is built with just [ty_rnil]
    and [ty_rcons] at the outermost level. *)

Inductive record_ty : ty -> Prop :=
  | rty_nil :
        record_ty ty_rnil
  | rty_cons : forall i T1 T2,
        record_ty (ty_rcons i T1 T2).

(** Similarly, a term is a record term if it is built with [tm_rnil]
    and [tm_rcons] *)

Inductive record_tm : tm -> Prop :=
  | rtm_nil :
        record_tm tm_rnil
  | rtm_cons : forall i t1 t2,
        record_tm (tm_rcons i t1 t2).

(** Note that [record_ty] and [record_tm] are not recursive -- they
    just check the outermost constructor.  The [well_formed_ty]
    property, on the other hand, verifies that the whole type is well
    formed in the sense that the tail of every record (the second
    argument to [ty_rcons]) is a record.

    Of course, we should also be concerned about ill-formed terms, not
    just types; but typechecking can rules those out without the help
    of an extra [well_formed_tm] definition because it already
    examines the structure of terms.  *)
(** LATER : should they fill in part of this as an exercise?  We
    didn't give rules for it above *)

Inductive well_formed_ty : ty -> Prop :=
  | wfty_base : forall i,
        well_formed_ty (ty_base i)
  | wfty_arrow : forall T1 T2,
        well_formed_ty T1 ->
        well_formed_ty T2 ->
        well_formed_ty (ty_arrow T1 T2)
  | wfty_rnil :
        well_formed_ty ty_rnil
  | wfty_rcons : forall i T1 T2,
        well_formed_ty T1 ->
        well_formed_ty T2 ->
        record_ty T2 ->
        well_formed_ty (ty_rcons i T1 T2).

Hint Constructors record_ty record_tm well_formed_ty.

(* ###################################################################### *)
(** *** Substitution *)

Fixpoint subst (x:id) (s:tm) (t:tm) : tm :=
  match t with
  | tm_var y => if beq_id x y then s else t
  | tm_abs y T t1 =>  tm_abs y T (if beq_id x y then t1 else (subst x s t1))
  | tm_app t1 t2 => tm_app (subst x s t1) (subst x s t2)
  | tm_proj t1 i => tm_proj (subst x s t1) i
  | tm_rnil => tm_rnil
  | tm_rcons i t1 tr1 => tm_rcons i (subst x s t1) (subst x s tr1)
  end.

(* ###################################################################### *)
(** *** Reduction *)

(** Next we define the values of our language.  A record is a value if
    all of its fields are. *)

Inductive value : tm -> Prop :=
  | v_abs : forall x T11 t12,
      value (tm_abs x T11 t12)
  | v_rnil : value tm_rnil
  | v_rcons : forall i v1 vr,
      value v1 ->
      value vr ->
      value (tm_rcons i v1 vr).

Hint Constructors value.

(** Utility functions for extracting one field from record type or
    term: *)

Fixpoint ty_lookup (i:id) (Tr:ty) : option ty :=
  match Tr with
  | ty_rcons i' T Tr' => if beq_id i i' then Some T else ty_lookup i Tr'
  | _ => None
  end.

Fixpoint tm_lookup (i:id) (tr:tm) : option tm :=
  match tr with
  | tm_rcons i' t tr' => if beq_id i i' then Some t else tm_lookup i tr'
  | _ => None
  end.

(** The [step] function uses the term-level lookup function (for the
    projection rule), while the type-level lookup is needed for
    [has_type]. *)

Reserved Notation "t1 '==>' t2" (at level 40).

Inductive step : tm -> tm -> Prop :=
  | ST_AppAbs : forall x T11 t12 v2,
         value v2 ->
         (tm_app (tm_abs x T11 t12) v2) ==> (subst x v2 t12)
  | ST_App1 : forall t1 t1' t2,
         t1 ==> t1' ->
         (tm_app t1 t2) ==> (tm_app t1' t2)
  | ST_App2 : forall v1 t2 t2',
         value v1 ->
         t2 ==> t2' ->
         (tm_app v1 t2) ==> (tm_app v1 t2')
  | ST_Proj1 : forall t1 t1' i,
        t1 ==> t1' ->
        (tm_proj t1 i) ==> (tm_proj t1' i)
  | ST_ProjRcd : forall tr i vi,
        value tr ->
        tm_lookup i tr = Some vi ->
        (tm_proj tr i) ==> vi
  | ST_Rcd_Head : forall i t1 t1' tr2,
        t1 ==> t1' ->
        (tm_rcons i t1 tr2) ==> (tm_rcons i t1' tr2)
  | ST_Rcd_Tail : forall i v1 tr2 tr2',
        value v1 ->
        tr2 ==> tr2' ->
        (tm_rcons i v1 tr2) ==> (tm_rcons i v1 tr2')

where "t1 '==>' t2" := (step t1 t2).

Tactic Notation "step_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "ST_AppAbs" | Case_aux c "ST_App1" | Case_aux c "ST_App2"
  | Case_aux c "ST_Proj1" | Case_aux c "ST_ProjRcd"
  | Case_aux c "ST_Rcd_Head" | Case_aux c "ST_Rcd_Tail" ].

Notation stepmany := (refl_step_closure step).
Notation "t1 '==>*' t2" := (stepmany t1 t2) (at level 40).

Hint Constructors step.

(* ###################################################################### *)
(** *** Typing *)

Definition context := partial_map ty.

(** Next we define the typing rules.  These are nearly direct
    transcriptions of the inference rules shown above.  The only major
    difference is the use of [well_formed_ty].  In the informal
    presentation we used a grammar that only allowed well formed
    record types, so we didn't have to add a separate check.

    We'd like to set things up so that that whenever [has_type Gamma t
    T] holds, we also have [well_formed_ty T].  That is, [has_type]
    never assigns ill-formed types to terms.  In fact, we prove this
    theorem below.

    However, we don't want to clutter the definition of [has_type]
    with unnecessary uses of [well_formed_ty].  Instead, we place
    [well_formed_ty] checks only where needed - where an inductive
    call to [has_type] won't already be checking the well-formedness
    of a type.

    For example, we check [well_formed_ty T] in the [T_Var] case,
    because there is no inductive [has_type] call that would
    enforce this.  Similarly, in the [T_Abs] case, we require a
    proof of [well_formed_ty T11] because the inductive call to
    [has_type] only guarantees that [T12] is well-formed.

    In the rules you must write, the only necessary [well_formed_ty]
    check comes in the [tm_nil] case.  *)

Inductive has_type : context -> tm -> ty -> Prop :=
  | T_Var : forall Gamma x T,
      Gamma x = Some T ->
      well_formed_ty T ->
      has_type Gamma (tm_var x) T
  | T_Abs : forall Gamma x T11 T12 t12,
      well_formed_ty T11 ->
      has_type (extend Gamma x T11) t12 T12 ->
      has_type Gamma (tm_abs x T11 t12) (ty_arrow T11 T12)
  | T_App : forall T1 T2 Gamma t1 t2,
      has_type Gamma t1 (ty_arrow T1 T2) ->
      has_type Gamma t2 T1 ->
      has_type Gamma (tm_app t1 t2) T2
  (* records: *)
  | T_Proj : forall Gamma i t Ti Tr,
      has_type Gamma t Tr ->
      ty_lookup i Tr = Some Ti ->
      has_type Gamma (tm_proj t i) Ti
  | T_RNil : forall Gamma,
      has_type Gamma tm_rnil ty_rnil
  | T_RCons : forall Gamma i t T tr Tr,
      has_type Gamma t T ->
      has_type Gamma tr Tr ->
      record_ty Tr ->
      record_tm tr ->
      has_type Gamma (tm_rcons i t tr) (ty_rcons i T Tr).

Hint Constructors has_type.

Tactic Notation "has_type_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "T_Var" | Case_aux c "T_Abs" | Case_aux c "T_App"
  | Case_aux c "T_Proj" | Case_aux c "T_RNil" | Case_aux c "T_RCons" ].

(* ###################################################################### *)
(** ** Examples *)

(** **** Exercise: 2 stars (examples) *)
(** Finish the proofs. *)

(** Feel free to use Coq's automation features in this proof.
    However, if you are not confident about how the type system works,
    you may want to carry out the proof first using the basic
    features ([apply] instead of [eapply], in particular) and then
    perhaps compress it using automation. *)

Lemma typing_example_2 :
  has_type empty
    (tm_app (tm_abs a (ty_rcons i1 (ty_arrow A A)
                      (ty_rcons i2 (ty_arrow B B)
                       ty_rnil))
              (tm_proj (tm_var a) i2))
            (tm_rcons i1 (tm_abs a A (tm_var a))
            (tm_rcons i2 (tm_abs a B (tm_var a))
             tm_rnil)))
    (ty_arrow B B).
Proof.
  (* FILL IN HERE *) Admitted.

(** Before starting to prove this fact (or the one above!), make sure
    you understand what it is saying. *)

Example typing_nonexample :
  ~ exists T,
      has_type (extend empty a (ty_rcons i2 (ty_arrow A A)
                                ty_rnil))
               (tm_rcons i1 (tm_abs a B (tm_var a)) (tm_var a))
               T.
Proof.
  (* FILL IN HERE *) Admitted.

Example typing_nonexample_2 : forall y,
  ~ exists T,
    has_type (extend empty y A)
           (tm_app (tm_abs a (ty_rcons i1 A ty_rnil)
                     (tm_proj (tm_var a) i1))
                   (tm_rcons i1 (tm_var y) (tm_rcons i2 (tm_var y) tm_rnil)))
           T.
Proof.
  (* FILL IN HERE *) Admitted.

(* ###################################################################### *)
(** ** Properties of Typing *)

(** The proofs of progress and preservation for this system are
    essentially the same as for the pure simply typed lambda-calculus,
    but we need to add some technical lemmas involving records. *)

(* ###################################################################### *)
(** *** Well-Formedness *)

Lemma wf_rcd_lookup : forall i T Ti,
  well_formed_ty T ->
  ty_lookup i T = Some Ti ->
  well_formed_ty Ti.
Proof with eauto.
  intros i T.
  ty_cases (induction T) Case; intros; try solve by inversion.
  Case "ty_rcons".
    inversion H. subst. unfold ty_lookup in H0.
    remember (beq_id i i0) as b. destruct b; subst...
    inversion H0. subst...  Qed.

Lemma step_preserves_record_tm : forall tr tr',
  record_tm tr ->
  tr ==> tr' ->
  record_tm tr'.
Proof.
  intros tr tr' Hrt Hstp.
  inversion Hrt; subst; inversion Hstp; subst; auto.
Qed.

Lemma has_type__wf : forall Gamma t T,
  has_type Gamma t T -> well_formed_ty T.
Proof with eauto.
  intros Gamma t T Htyp.
  has_type_cases (induction Htyp) Case...
  Case "T_App".
    inversion IHHtyp1...
  Case "T_Proj".
    eapply wf_rcd_lookup...
Qed.

(* ###################################################################### *)
(** *** Field Lookup *)

(** Lemma: If [empty |- v : T] and [ty_lookup i T] returns [Some Ti],
     then [tm_lookup i v] returns [Some ti] for some term [ti] such
     that [has_type empty ti Ti].

    Proof: By induction on the typing derivation [Htyp].  Since
      [ty_lookup i T = Some Ti], [T] must be a record type, this and
      the fact that [v] is a value eliminate most cases by inspection,
      leaving only the [T_RCons] case.

      If the last step in the typing derivation is by [T_RCons], then
      [t = tm_rcons i0 t tr] and [T = ty_rcons i0 T Tr] for some [i0],
      [t], [tr], [T] and [Tr].

      This leaves two possiblities to consider - either [i0 = i] or
      not.

      - If [i = i0], then since [ty_lookup i (ty_rcons i0 T Tr) = Some
        Ti] we have [T = Ti].  It follows that [t] itself satisfies
        the theorem.

      - On the other hand, suppose [i <> i0].  Then
[[
        ty_lookup i T = ty_lookup i Tr
]]
        and
[[
        tm_lookup i t = tm_lookup i tr,
]]
        so the result follows from the induction hypothesis. [] *)

Lemma lookup_field_in_value : forall v T i Ti,
  value v ->
  has_type empty v T ->
  ty_lookup i T = Some Ti ->
  exists ti, tm_lookup i v = Some ti /\ has_type empty ti Ti.
Proof with eauto.
  intros v T i Ti Hval Htyp Hget.
  remember (@empty ty) as Gamma.
  has_type_cases (induction Htyp) Case; subst; try solve by inversion...
  Case "T_RCons".
    simpl in Hget. simpl. destruct (beq_id i i0).
    SCase "i is first".
      simpl. inversion Hget. subst.
      exists t...
    SCase "get tail".
      destruct IHHtyp2 as [vi [Hgeti Htypi]]...
      inversion Hval... Qed.

(* ###################################################################### *)
(** *** Progress *)

Theorem progress : forall t T,
     has_type empty t T ->
     value t \/ exists t', t ==> t'.
Proof with eauto.
  (* Theorem: Suppose empty |- t : T.  Then either
       1. t is a value, or
       2. t ==> t' for some t'.
     Proof: By induction on the given typing derivation. *)
  intros t T Ht.
  remember (@empty ty) as Gamma.
  generalize dependent HeqGamma.
  has_type_cases (induction Ht) Case; intros HeqGamma; subst.
  Case "T_Var".
    (* The final rule in the given typing derivation cannot be [T_Var],
       since it can never be the case that [empty |- x : T] (since the
       context is empty). *)
    inversion H.
  Case "T_Abs".
    (* If the [T_Abs] rule was the last used, then [t = tm_abs x T11 t12],
       which is a value. *)
    left...
  Case "T_App".
    (* If the last rule applied was T_App, then [t = t1 t2], and we know
       from the form of the rule that
         [empty |- t1 : T1 -> T2]
         [empty |- t2 : T1]
       By the induction hypothesis, each of t1 and t2 either is a value
       or can take a step. *)
    right.
    destruct IHHt1; subst...
    SCase "t1 is a value".
      destruct IHHt2; subst...
      SSCase "t2 is a value".
      (* If both [t1] and [t2] are values, then we know that
         [t1 = tm_abs x T11 t12], since abstractions are the only values
         that can have an arrow type.  But
         [(tm_abs x T11 t12) t2 ==> subst x t2 t12] by [ST_AppAbs]. *)
        inversion H; subst; try (solve by inversion).
        exists (subst x t2 t12)...
      SSCase "t2 steps".
        (* If [t1] is a value and [t2 ==> t2'], then [t1 t2 ==> t1 t2']
           by [ST_App2]. *)
        destruct H0 as [t2' Hstp]. exists (tm_app t1 t2')...
    SCase "t1 steps".
      (* Finally, If [t1 ==> t1'], then [t1 t2 ==> t1' t2] by [ST_App1]. *)
      destruct H as [t1' Hstp]. exists (tm_app t1' t2)...
  Case "T_Proj".
    (* If the last rule in the given derivation is [T_Proj], then
       [t = tm_proj t i] and
           [empty |- t : (ty_rcd Tr)]
       By the IH, [t] either is a value or takes a step. *)
    right. destruct IHHt...
    SCase "rcd is value".
      (* If [t] is a value, then we may use lemma
         [lookup_field_in_value] to show [tm_lookup i t = Some ti] for
         some [ti] which gives us [tm_proj i t ==> ti] by [ST_ProjRcd]
         *)
      destruct (lookup_field_in_value _ _ _ _ H0 Ht H) as [ti [Hlkup _]].
      exists ti...
    SCase "rcd_steps".
      (* On the other hand, if [t ==> t'], then [tm_proj t i ==> tm_proj t' i]
         by [ST_Proj1]. *)
      destruct H0 as [t' Hstp]. exists (tm_proj t' i)...
  Case "T_RNil".
    (* If the last rule in the given derivation is [T_RNil], then
       [t = tm_rnil], which is a value. *)
    left...
  Case "T_RCons".
    (* If the last rule is [T_RCons], then [t = tm_rcons i t tr] and
         [empty |- t : T]
         [empty |- tr : Tr]
       By the IH, each of [t] and [tr] either is a value or can take
       a step. *)
    destruct IHHt1...
    SCase "head is a value".
      destruct IHHt2; try reflexivity.
      SSCase "tail is a value".
      (* If [t] and [tr] are both values, then [tm_rcons i t tr]
         is a value as well. *)
        left...
      SSCase "tail steps".
        (* If [t] is a value and [tr ==> tr'], then
           [tm_rcons i t tr ==> tm_rcons i t tr'] by
           [ST_Rcd_Tail]. *)
        right. destruct H2 as [tr' Hstp].
        exists (tm_rcons i t tr')...
    SCase "head steps".
      (* If [t ==> t'], then
         [tm_rcons i t tr ==> tm_rcons i t' tr]
         by [ST_Rcd_Head]. *)
      right. destruct H1 as [t' Hstp].
      exists (tm_rcons i t' tr)...  Qed.

(* ###################################################################### *)
(** *** Context Invariance *)

Inductive appears_free_in : id -> tm -> Prop :=
  | afi_var : forall x,
      appears_free_in x (tm_var x)
  | afi_app1 : forall x t1 t2,
      appears_free_in x t1 -> appears_free_in x (tm_app t1 t2)
  | afi_app2 : forall x t1 t2,
      appears_free_in x t2 -> appears_free_in x (tm_app t1 t2)
  | afi_abs : forall x y T11 t12,
        y <> x  ->
        appears_free_in x t12 ->
        appears_free_in x (tm_abs y T11 t12)
  | afi_proj : forall x t i,
     appears_free_in x t ->
     appears_free_in x (tm_proj t i)
  | afi_rhead : forall x i ti tr,
      appears_free_in x ti ->
      appears_free_in x (tm_rcons i ti tr)
  | afi_rtail : forall x i ti tr,
      appears_free_in x tr ->
      appears_free_in x (tm_rcons i ti tr).

Hint Constructors appears_free_in.

Lemma context_invariance : forall Gamma Gamma' t S,
     has_type Gamma t S  ->
     (forall x, appears_free_in x t -> Gamma x = Gamma' x)  ->
     has_type Gamma' t S.
Proof with eauto.
  intros. generalize dependent Gamma'.
  has_type_cases (induction H) Case;
    intros Gamma' Heqv...
  Case "T_Var".
    apply T_Var... rewrite <- Heqv...
  Case "T_Abs".
    apply T_Abs... apply IHhas_type. intros y Hafi.
    unfold extend. remember (beq_id x y) as e.
    destruct e...
  Case "T_App".
    apply T_App with T1...
  Case "T_RCons".
    apply T_RCons...  Qed.

Lemma free_in_context : forall x t T Gamma,
   appears_free_in x t ->
   has_type Gamma t T ->
   exists T', Gamma x = Some T'.
Proof with eauto.
  intros x t T Gamma Hafi Htyp.
  has_type_cases (induction Htyp) Case; inversion Hafi; subst...
  Case "T_Abs".
    destruct IHHtyp as [T' Hctx]... exists T'.
    unfold extend in Hctx.
    apply not_eq_beq_id_false in H3. rewrite H3 in Hctx...
Qed.

(* ###################################################################### *)
(** *** Preservation *)

Lemma substitution_preserves_typing : forall Gamma x U v t S,
     has_type (extend Gamma x U) t S  ->
     has_type empty v U   ->
     has_type Gamma (subst x v t) S.
Proof with eauto.
  (* Theorem: If Gamma,x:U |- t : S and empty |- v : U, then
     Gamma |- (subst x v t) S. *)
  intros Gamma x U v t S Htypt Htypv.
  generalize dependent Gamma. generalize dependent S.
  (* Proof: By induction on the term t.  Most cases follow directly
     from the IH, with the exception of tm_var, tm_abs, tm_rcons.
     The former aren't automatic because we must reason about how the
     variables interact. In the case of tm_rcons, we must do a little
     extra work to show that substituting into a term doesn't change
     whether it is a record term. *)
  tm_cases (induction t) Case;
    intros S Gamma Htypt; simpl; inversion Htypt; subst...
  Case "tm_var".
    simpl. rename i into y.
    (* If t = y, we know that
         [empty |- v : U] and
         [Gamma,x:U |- y : S]
       and, by inversion, [extend Gamma x U y = Some S].  We want to
       show that [Gamma |- subst x v y : S].

       There are two cases to consider: either [x=y] or [x<>y]. *)
    remember (beq_id x y) as e. destruct e.
    SCase "x=y".
    (* If [x = y], then we know that [U = S], and that [subst x v y = v].
       So what we really must show is that if [empty |- v : U] then
       [Gamma |- v : U].  We have already proven a more general version
       of this theorem, called context invariance. *)
      apply beq_id_eq in Heqe. subst.
      unfold extend in H0. rewrite <- beq_id_refl in H0.
      inversion H0; subst. clear H0.
      eapply context_invariance...
      intros x Hcontra.
      destruct (free_in_context _ _ S empty Hcontra) as [T' HT']...
      inversion HT'.
    SCase "x<>y".
    (* If [x <> y], then [Gamma y = Some S] and the substitution has no
       effect.  We can show that [Gamma |- y : S] by [T_Var]. *)
      apply T_Var... unfold extend in H0. rewrite <- Heqe in H0...
  Case "tm_abs".
    rename i into y. rename t into T11.
    (* If [t = tm_abs y T11 t0], then we know that
         [Gamma,x:U |- tm_abs y T11 t0 : T11->T12]
         [Gamma,x:U,y:T11 |- t0 : T12]
         [empty |- v : U]
       As our IH, we know that forall S Gamma,
         [Gamma,x:U |- t0 : S -> Gamma |- subst x v t0 S].

       We can calculate that
         subst x v t = tm_abs y T11 (if beq_id x y
                                      then t0
                                      else subst x v t0)
       And we must show that [Gamma |- subst x v t : T11->T12].  We know
       we will do so using [T_Abs], so it remains to be shown that:
         [Gamma,y:T11 |- if beq_id x y then t0 else subst x v t0 : T12]
       We consider two cases: [x = y] and [x <> y].
    *)
    apply T_Abs...
    remember (beq_id x y) as e. destruct e.
    SCase "x=y".
    (* If [x = y], then the substitution has no effect.  Context
       invariance shows that [Gamma,y:U,y:T11] and [Gamma,y:T11] are
       equivalent.  Since the former context shows that [t0 : T12], so
       does the latter. *)
      eapply context_invariance...
      apply beq_id_eq in Heqe. subst.
      intros x Hafi. unfold extend.
      destruct (beq_id y x)...
    SCase "x<>y".
    (* If [x <> y], then the IH and context invariance allow us to show that
         [Gamma,x:U,y:T11 |- t0 : T12]       =>
         [Gamma,y:T11,x:U |- t0 : T12]       =>
         [Gamma,y:T11 |- subst x v t0 : T12] *)
      apply IHt. eapply context_invariance...
      intros z Hafi. unfold extend.
      remember (beq_id y z) as e0. destruct e0...
      apply beq_id_eq in Heqe0. subst.
      rewrite <- Heqe...
  Case "tm_rcons".
    apply T_RCons... inversion H7; subst; simpl...
Qed.

Theorem preservation : forall t t' T,
     has_type empty t T  ->
     t ==> t'  ->
     has_type empty t' T.
Proof with eauto.
  intros t t' T HT.
  (* Theorem: If [empty |- t : T] and [t ==> t'], then [empty |- t' : T]. *)
  remember (@empty ty) as Gamma. generalize dependent HeqGamma.
  generalize dependent t'.
  (* Proof: By induction on the given typing derivation.  Many cases are
     contradictory ([T_Var], [T_Abs]) or follow directly from the IH
     ([T_RCons]).  We show just the interesting ones. *)
  has_type_cases (induction HT) Case;
    intros t' HeqGamma HE; subst; inversion HE; subst...
  Case "T_App".
    (* If the last rule used was [T_App], then [t = t1 t2], and three rules
       could have been used to show [t ==> t']: [ST_App1], [ST_App2], and
       [ST_AppAbs]. In the first two cases, the result follows directly from
       the IH. *)
    inversion HE; subst...
    SCase "ST_AppAbs".
      (* For the third case, suppose
           [t1 = tm_abs x T11 t12]
         and
           [t2 = v2].  We must show that [empty |- subst x v2 t12 : T2].
         We know by assumption that
             [empty |- tm_abs x T11 t12 : T1->T2]
         and by inversion
             [x:T1 |- t12 : T2]
         We have already proven that substitution_preserves_typing and
             [empty |- v2 : T1]
         by assumption, so we are done. *)
      apply substitution_preserves_typing with T1...
      inversion HT1...
  Case "T_Proj".
  (* If the last rule was [T_Proj], then [t = tm_proj t1 i].  Two rules
     could have caused [t ==> t']: [T_Proj1] and [T_ProjRcd].  The typing
     of [t'] follows from the IH in the former case, so we only
     consider [T_ProjRcd].

     Here we have that [t] is a record value.  Since rule T_Proj was
     used, we know [has_type empty t Tr] and [ty_lookup i Tr = Some
     Ti] for some [i] and [Tr].  We may therefore apply lemma
     [lookup_field_in_value] to find the record element this
     projection steps to. *)
    destruct (lookup_field_in_value _ _ _ _ H2 HT H)
      as [vi [Hget Htyp]].
    rewrite H4 in Hget. inversion Hget. subst...
  Case "T_RCons".
  (* If the last rule was [T_RCons], then [t = tm_rcons i t tr] for
     some [i], [t] and [tr] such that [record_tm tr].  If the step is
     by [ST_Rcd_Head], the result is immediate by the IH.  If the step
     is by [ST_Rcd_Tail], [tr ==> tr2'] for some [tr2'] and we must also
     use lemma [step_preserves_record_tm] to show [record_tm tr2']. *)
    apply T_RCons... eapply step_preserves_record_tm...
Qed.
(** [] *)

End STLCExtendedRecords.

