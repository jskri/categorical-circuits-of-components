# Introduction

A major challenge in building software systems is complexity. As systems grow,
their complexity tends to explode, making them hard to reason about. Often the
situation becomes so bad that the only solution is to build a new system to
replace the faulty one.

Ideally, one would be able to define a system by assembling well-understood
components. Their composition should then be well-defined and easy to
understand. The building process could be iterative and each new layer of
components, built on lower-level ones, should be equally easy to understand and
manipulate. One should also have a way to optimise components in a systematic
way.

To approach these goal, we will first give a precise definition of a component.
Then, we'll define how to compose several components. However, without
constraints such composition cannot be expressed formulaically and optimisation,
if possible, cannot be done in a systematic way.

To discipline composition, we will leverage constructions from category theory,
allowing us to gradually enrich a language of components. First, the bare notion
of category will give us associativity, which enables grouping of components as
a first form of abstraction. Then, the notion of cartesian category will allow
us to duplicate information and parallelise work. This will be completed by the
notion of cocartesian category that will add a way to join parallel lines of
components. Finally, compact closed categories will allow us to make data flow
in both direction and create feedbacks and loops. With this final addition, we
will be able to implement real circuits of components.

At each step, algebraic identities will be given, enabling a way to "calculate"
circuits and optimise them in a rigorous way.



# Component definition and examples

## Definition

Informally, a component is defined to have input wires, output wires and a
state. Each wire has a type and may hold a value. A component may act by:

- consuming values on its input wires
- producing values on its output wires
- changing its state

More formally, we first give the following context:

- a set $W$ of wires
- a set $Ty$ of types, a type being itself a set
- a function $type : W → Ty$
- a set $T$ of totally ordered dates

We define $V = (⋃Ty) + 1$, with $+$ being the disjoint union and $1 = {⋆}$. $⋆$
will represent an "empty" state, or the absence of value on a wire. When writing
$S + 1$ for some set $S$, we will always assume that $⋆$ does not belong to $S$,
thus $⋆$ will non-ambiguously denote the element of $1$.

A component is then a tuple $(I, O, s, up)$ where:

- $I : 𝒫(W)$ is the set of input wires ($𝒫(W)$ is the set of subsets of $W$)

- $O : 𝒫(W)$ is the set of output wires

- $s : S$ is the component state

- $up : T × (IO → V) × S → (IO → V) × S$ is the update function where
    + $IO = I ∪ O$
    + Any function $v: IO → V$ must satisfy $v(w) : type(w)$
    + With $up(t, v, s) = (v', s')$:
        - $v(w) ≠ ⋆ ∧ v'(w) = ⋆ ⇒ w : I$ (consumption can only happen on an input wire)
        - $v(w) = ⋆ ∧ v'(w) ≠ ⋆ ⇒ w : O$ (production can only happen on an output wire)

**Note**: $I$ and $O$ may be empty. $I$ and $O$ may have a non-empty
intersection, i.e. a wire may be both an input and an output wire (i.e. a
"loop" wire).


## Examples

### Mathematical function

```diagram
title:  The functional component $f$.
basename: add

α:ℕ ┌─────────────┐
────┤      f      │ γ:ℕ
────┤     add     ├────
β:ℕ └─────────────┘
```

The component $f$ has two input wires ($α, β$) of type $ℕ$ ($0, 1, ...$), and
one output wire ($γ$) of type $ℕ$. It is stateless and performs an addition.

More precisely, $f = ({α, β}, {γ}, ⋆, add)$ where:

- $add(t, (α ⟼ n, β ⟼ m, γ ⟼ ⋆), ⋆) = ((α ⟼ ⋆, β ⟼ ⋆, γ ⟼ n + m), ⋆)$
- $add(_, w, s) = (w, s)$ (i.e. no-op)

**Note**: When we write $α ⟼ n$, it is implied that $n ≠ ⋆$. The same holds in
the rest of the document.

The no-op equation applies to cases where some input wires do not have values,
or some output wires do have a value. This no-op fallback is omitted in the rest
of the document.

### Stateful procedure

```diagram
title: The procedural component $g$.
basename: store

 α:Str┌─────────────┐ γ:ℤ
──────┤      g      ├────────
──────┤    store    ├────────
 β:ℤ  └─────────────┘ δ:Error
```

The component $g$ is a dictionary that associates names to integers ($..., -1, 0, 1, ...$).
If the key exists, it updates the stored value and returns the old value.
Otherwise, it returns an error.

$g = ({α, β}, {γ, δ}, dict, store)$ where:

- $dict: Str → ℤ + 1$  ($⋆$ being the value of "unknown" keys)

- $store(t, (α ⟼ k, β ⟼ v, γ ⟼ ⋆, δ ⟼ ⋆), dict) = (
    (α ⟼ ⋆,
     β ⟼ ⋆,
     γ ⟼ dict(k),
     δ ⟼ if  dict(k) = ⋆  then  "unknown key"  else  ⋆),
    key ⟼ if  key = k  then  v  else  dict(key))$.

$k$ is the dictionary key, $v$ is the new value. The error wire $δ$ is needed
since an absence of dictionary value ($⋆$), when put on the $γ$ wire, is
interpreted as an absence of wire value.

### Filter

```diagram
title: The time-based filtering component $h$.
basename: filter

    ┌─────────────┐
α:ℝ │      h      │ β:ℝ
────┤    filter   ├────
    └─────────────┘
```

The component $h$ fixes an output rate and clamps values in $[0, 1]$.

$h = ({α}, {β}, t_last, filter)$ where:

- $filter(t, (α ⟼ x, β ⟼ ⋆), t_last) = (
    (α ⟼ ⋆,
     β ⟼ if  ok(t)  then  clamp(x, 0, 1)  else  ⋆),
    if  ok(t)  then  t  else  t_last)$ where:

    + $ok(t) = t - t_last > 1$

    + $clamp(x, low, high) =
        if  low ≤ x  then
          if  x ≤ high  then  x  else  high
        else
          low$

### Source

```diagram
title: The source component i.
basename: read

┌─────────────┐
│      i      │ α:ℝ
│    read     ├────────
└─────────────┘
```

The component $i$ reads a value from a source and outputs it. One example of a
source could be a hardware sensor.

$i = ({}, {α}, source, read)$ where:

- $source: T → ℝ$
- $read(t, (α ⟼ ⋆), source) = ((α ⟼ source(t)), source)$

$source$ is a "continuum" of reals. $i$ puts the real at time $t$ on wire $α$,
only if $α$ is empty. That is, $i$'s output rate is only bounded by the consumer
of $α$.



# Composition

## Example

We start by an example. We compose the already introduced components $h$ and
$i$, with a rewiring of $f$ on wires $γ$, $δ$, $ε$, and a new component $j$ that
outputs a string representation of its input pair (e.g.
$up_j(t, (β ⟼ 3.4, ε ⟼ 7, ζ ⟼ ⋆), ⋆) = (β ⟼ ⋆, ε ⟼ ⋆, ζ ⟼ "(3.4, 7)"), ⋆)$, in
the following manner:

```diagram
title: Component $m$ that composes components $f'$, $h$, $i$ and $j$
basename: composition-add-filter-read-str

                                 m
    ┌─────────────────────────────────────────────────────┐
    │ ┌─────────────┐     ┌─────────────┐                 │
    │ │      i      │ α:ℝ │      h      │ β:ℝ ┌─────────┐ │
    │ │    read     ├─────┤    filter   ├─────┤         │ │
    │ └─────────────┘     └─────────────┘     │    j    │ │ ζ:𝕊
γ:ℕ │ ┌─────────────┐                         │   str   ├─┼────
────┼─┤      f'     │           ε:ℕ           │         │ │
────┼─┤     add     ├─────────────────────────┤         │ │
δ:ℕ │ └─────────────┘                         └─────────┘ │
    └─────────────────────────────────────────────────────┘
```

**Note**: $𝕊$ is the set of all strings.

$m = (I, O, s, up)$ is a component with:

- $I = {γ, δ}$

- $O = {ζ}$

- $s = (v_in, (s_f', s_h, s_i, s_j))$ where
    + $v_in : {α, β, ε} → V$ gives the values of internal wires
    + $s_k$ is the state of component $k$

- $up$ updates all components and sets the wire values according to the changes
  (see below).

A partial trace for $m$ could be (showing wire values only):

1. $(α ⟼ ⋆, β ⟼ ⋆, γ ⟼ 3, δ ⟼ 5, ε ⟼ ⋆, ζ ⟼ ⋆)$

2. $(α ⟼ 0.6, β ⟼ ⋆, γ ⟼ ⋆, δ ⟼ ⋆, ε ⟼ 8, ζ ⟼ ⋆)$

3. $(α ⟼ ⋆, β ⟼ 0.6, γ ⟼ 1, δ ⟼ 2, ε ⟼ 8, ζ ⟼ ⋆)$

4. $(α ⟼ 5.8, β ⟼ ⋆, γ ⟼ 1, δ ⟼ 2, ε ⟼ ⋆, ζ ⟼ "(0.6, 8)")$

5. $(α ⟼ ⋆, β ⟼ 1, γ ⟼ ⋆, δ ⟼ ⋆, ε ⟼ 3, ζ ⟼ "(0.6, 8)")$


## Definition

Formally, the component $c = (I, O, s, up)$ composed out of
${c_1 = (I_1, O_1, s_1, up_1), c_2 = (I_2, O_2, s_2, up_2), ...}$ is defined by:

  - $I = (⋃I_k) \ (⋃O_k)$

  - $O = (⋃O_k) \ (⋃I_k)$

  - $s = (v_in, ∏{s_k})$

  - $up(t, v, s) = (v', (v'_in, ∏{s'_k}))$

  - $W_in = (⋃W_k) \ IO$

  - $W_k = IO_k$ with $IO_k = I_k ∪ O_k$

  - $v' = v‾|_{IO}$

  - $v'_in = v‾|_{W_in}$

  - $(v'_k, s'_k) = up_k(t, (v ∪ v_in)|_{W_k}, s_k)$

  - $v‾: (⋃W_k) → V$

  - $v‾(w) = if w : wires_D
             then choose val : vals_D | (w, val) : ⋃D_k
             else (v ∪ v_in)(w)$

  - $wires_D = {w | (w, _) : ⋃D_k}$

  - $vals_D = {val | (_, val) : ⋃D_k}$

  - $D_k = {(w, v'_k(w)) | w ∈ W_k ∧ v_k(w) ≠ v'_k(w)}$

**Note**: $f|_A$ is the restriction of the function $f$ to the subset $A$ of its
domain.

**Note**: $D_k$ is the wire changes ("diffs") for component $k$.

**Note**: $choose$ selects an arbitrary but fixed element in a set. Since a wire
connects at most two components (one input and one output), due to update
constraints $val(w) \ {⋆}$ has one element (in the $else$), making the above
$choose$ expression non-ambiguous.

**Note**: $v ∪ v_in$ is a function that is the union of $v$ and $v_in$, which is
well-defined since $v$ and $v_in$ domains are disjoint.

Additionally, we require that a wire cannot be the input (resp. output) of
several components:

$∀ w : W . |Ci_w| ∈ {0, 1}  ∧  |Co_w| ∈ {0, 1}$ where:

- $Ci_w = ⋃ {(I, _, _, _) | w : I}$ (all components that have $w$ as input)
- $Co_w = ⋃ {(_, O, _, _) | w : O}$ (all components that have $w$ as output)

**Note**: It is possible that $|Ci_w + Co_w| = 0$, meaning the wire passes
through the collection without entering or exiting any component.

Thus, any set of components with the above constraints can be considered a
component.


## Structured composition

Even if any set of components can be considered as a component (up to wire
constraint), we want to identify more constrained forms of composition that
will allow us to:

- describe components as formulae
- manipulate formulae algebraically
- use algebraic identities to transform a component into a more optimised one


### Sequential

If a component $c_1$'s output wires are components $c_2$'s input wires, $c_1$
and $c_2$ can be composed sequentially.

Example:

```diagram
title: A sequential composition.
basename: sequential-composition

┌─────────────────────────────────────┐
│ ┌─────────────┐     ┌─────────────┐ │
│ │      i      │ α:ℝ │      h      │ │β:ℝ
│ │    read     ├─────┤    filter   ├─┼────
│ └─────────────┘     └─────────────┘ │
└─────────────────────────────────────┘
```

Moreover, if:

- $c_1$ has input wires

- $c_2$ has output wires

- $c_1$ updates by consuming all its input wires

- $c_2$ updates by producing on all its output wires

- $c_1$ and $c_2$ are stateless (i.e. state is $⋆$)

Then, $c_1$ and $c_2$ represent functions and their sequential composition is
function composition.

```lemma
name: id

For each type $t$, there is an $id_t$ component that merely forwards
inputs to outputs, i.e.

$$id_t = ({α}, {β}, ⋆, (_, (α ⟼ x, β ⟼ ⋆), ⋆) ⟼ ((α ⟼ ⋆, β ⟼ x), ⋆)$$

where wires $α, β$ have type $t$. Precomposing or post-composing with an
identity component does not alter in any way the input or the output.
```

```lemma
name: seq-assoc

Sequential composition is associative.
```

```lemma
name: seq-cat

Sequential composition forms a category (by lemmas id and seq-cat).
```

Consequently, we get the following identities (with $f ; g$ denoting the
sequential composition of components $f$ and $g$, and $id$ denoting $id_t$ for
the appropriate type $t$):

- $f ; id = f$
- $id ; f = f$
- $(f ; g) ; h = f ; (g ; h)$

Equality means that, given equal inputs, both components have equal outputs.

The third identity means that components in a chain of sequential composition
may be regrouped freely, as long as their relative order is unchanged. For
instance, regrouping $f$ and $g$ yields:

```diagram
title: First way to group components.
basename: associativity-1

             f;g
     ┌─────────────────┐
 α:A │ ┌───┐ β:B ┌───┐ │ γ:C ┌───┐ δ:D         
─────┼─┤ f ├─────┤ g ├─┼─────┤ h ├─────
     │ └───┘     └───┘ │     └───┘
     └─────────────────┘
```

By associativity, this is equivalent to:

```diagram
title: Second way to group components.
basename: associativity-2

                      g;h
              ┌─────────────────┐
 α:A  ┌───┐β:B│ ┌───┐ γ:C ┌───┐ │δ:D         
──────┤ f ├───┼─┤ g ├─────┤ h ├─┼────
      └───┘   │ └───┘     └───┘ │
              └─────────────────┘
```

This way of grouping components is a first way to handle complexity by enabling
a hierarchical organization of components.


### Parallel

If two components $c_1, c_2$ have no wire in common, they can be "stacked" into
a new component:

```diagram
title: A parallel composition.
basename: parallel-composition

        f×g
     ┌───────┐
 α:A │ ┌───┐ │ β:B
─────┼─┤ f ├─┼────
     │ └───┘ │
 γ:C │ ┌───┐ │ δ:D
─────┼─┤ g ├─┼────
     │ └───┘ │
     └───────┘
```

An important variant is when both components have (wires with) the same input
type. Then we can compose them in parallel by duplicating the input:

```diagram
title: A split composition.
basename: split-composition

           f△g
   ┌──────────────────┐
   │        β:A ┌───┐ │δ:X
α:A│ ┌───┐ ┌────┤ f ├─┼───
───┼─┤ △ ├─┘    └───┘ │
   │ │   ├─┐γ:A ┌───┐ │ε:Y
   │ └───┘ └────┤ g ├─┼───
   │            └───┘ │
   └──────────────────┘
```

$△ = ({α}, {β, γ}, ⋆, dup)$ where

$dup(_, (α ⟼ x, β ⟼ ⋆, γ ⟼ ⋆), ⋆) = ((α ⟼ ⋆, β ⟼ x, γ ⟼ x), ⋆))$

We also define helper components that have two inputs and "extract" only one of
them:

```diagram
title: The $exl$ component.
basename: exl

α:A ┌─────┐
────┤     │ γ:A
    │ exl ├────
────┤     │
β:B └─────┘
```

```diagram
title: The $exr$ component.
basename: exr

α:A ┌─────┐
────┤     │ γ:B
    │ exr ├────
────┤     │
β:B └─────┘
```

$exl = ({α, β}, {γ}, ⋆, first)$

$exr = ({α, β}, {γ}, ⋆, second)$

where:

- $first(_, (α ⟼ x, β ⟼ y, γ ⟼ ⋆), ⋆) = ((α ⟼ ⋆, β ⟼ ⋆, γ ⟼ x), ⋆))$
- $second(_, (α ⟼ x, β ⟼ y, γ ⟼ ⋆), ⋆) = ((α ⟼ ⋆, β ⟼ ⋆, γ ⟼ y), ⋆))$

We also define a component that "forgets" its input ("information loss"):

```diagram
title: The $!$ component.
basename: forget

α:A ┌───┐ β:1
────┤ ! ├────
    └───┘
```

For each input, $!$ consumes it and produces a $⋆$ value ($1 = {⋆}$). Obviously,
$⋆$ as a value on the wire must be distinguished from $⋆$ as an absence of value
on the wire. In this document, we won't need this distinction but any notation
will do.


```lemma
name: prod-cart

Product composition (with $△$, $exl$, $exr$, $!$) forms a cartesian category.
```
 
From cartesian category, we get the following identities ($f$ and $g$ are not
related to previously defined components with the same names):

- $f × g = (exl ; f) △ (exr ; g)$
- $(f △ g) ; exl = f$
- $(f △ g) ; exr = g$
- $(h ; exl) △ (h ; exr) = h$
- $exl △ exr = id$
- $(h △ k) ; (f × g) = (h ; f) △ (k ; g)$
- $id × id = id$
- $(h × k) ; (f × g) = (h ; f) × (k ; g)$
- $h ; (f △ g) = (h ; f) △ (h ; g)$

We illustrate only the last identity, that when read from right to left, can be
used to optimise a component through factorisation (wire names are omitted):

```diagram
title: The "seq-split" identity.
basename: seq-split-identity

        (h ; f) △ (h ; g)                      h ; (f △ g)
 ┌─────────────────────────────┐       ┌─────────────────────────┐
 │                h ; f        │       │             f △ g       │
 │         ┌─────────────────┐ │       │       ┌───────────────┐ │
 │       A │ ┌───┐  B  ┌───┐ │ │C      │       │       B ┌───┐ │ │C
 │       ┌─┼─┤ h ├─────┤ f ├─┼─┼─      │       │       ┌─┤ f ├─┼─┼─
A│ ┌───┐ │ │ └───┘     └───┘ │ │      A│ ┌───┐B│ ┌───┐ │ └───┘ │ │
─┼─┤ △ ├─┘ └─────────────────┘ │   =  ─┼─┤ h ├─┼─┤ △ ├─┘       │ │
 │ │   ├─┐ ┌─────────────────┐ │       │ └───┘ │ │   ├─┐       │ │
 │ └───┘ │ │ ┌───┐     ┌───┐ │ │       │       │ └───┘ │ ┌───┐ │ │
 │       └─┼─┤ h ├─────┤ g ├─┼─┼─      │       │       └─┤ g ├─┼─┼─
 │       A │ └───┘  B  └───┘ │ │D      │       │       B └───┘ │ │D
 │         └─────────────────┘ │       │       └───────────────┘ │
 │                h ; g        │       │                         │
 └─────────────────────────────┘       └─────────────────────────┘
```

### Alternative

Product $f × g$ updates by consuming on all its inputs and producing on all its
outputs at once. Sum $f + g$ is another form of stacking that updates by
consuming and producing on only on wire at a time. In fact, only one input
(resp. output) wire may have a value at a time.

```diagram
title: An alternative composition.
basename: alternative-composition

        f+g
     ┌───────┐
 α:A │ ┌───┐ │ β:B
─────┼─┤ f ├─┼─────
  +  │ └───┘ │  +
 γ:C │ ┌───┐ │ δ:D
─────┼─┤ g ├─┼─────
     │ └───┘ │
     └───────┘
```

In the above diagram, there is either a value on $α$ or on $γ$ (denoted by
the $+$ between the two wires). If $α$ (resp. $γ$) has a value, updating $f + g$
means updating $f$ (resp. $g$), that may produce a value on $β$ (resp. $δ$).

The following definitions are "mirrors" of the definitions in the product
section.

An important variant is when both components have (wires with) the same output
type. Then we can compose them in parallel by joining the outputs:

```diagram
title: A join-composition.
basename: join-composition

          f ▽ g
   ┌──────────────────┐
α:A│ ┌───┐ γ:C        │
───┼─┤ f ├────┐ ┌───┐ │ε:C
 + │ └───┘  + └─┤ ▽ ├─┼───
   │ ┌───┐    ┌─┤   │ │
───┼─┤ g ├────┘ └───┘ │
β:B│ └───┘ δ:C        │
   └──────────────────┘
```

$▽ = ({γ, δ}, {ε}, ⋆, join)$ where

$join(_, (γ ⟼ x, δ ⟼ ⋆, ε ⟼ ⋆), ⋆) = ((γ ⟼ ⋆, δ ⟼ ⋆, ε ⟼ x), ⋆))$

$join(_, (γ ⟼ ⋆, δ ⟼ x, ε ⟼ ⋆), ⋆) = ((γ ⟼ ⋆, δ ⟼ ⋆, ε ⟼ x), ⋆))$

We also define helper components that have two inputs and "inject" only one of
them:

```diagram
title: The "inl" component.
basename: inl

    ┌─────┐ β:A
α:A │     ├────
────┤ inl │  +
    │     ├────
    └─────┘ γ:B
```
                   
```diagram
title: The "inr" component.
basename: inr

    ┌─────┐ β:A
α:B │     ├────
────┤ inr │  +
    │     ├────
    └─────┘ γ:B
```

$inl = ({α}, {β, γ}, ⋆, first)$

$inr = ({α}, {β, γ}, ⋆, second)$

where:

- $first (_, (α ⟼ x, β ⟼ ⋆, γ ⟼ ⋆), ⋆) = ((α ⟼ ⋆, β ⟼ x, γ ⟼ ⋆), ⋆))$
- $second(_, (α ⟼ x, β ⟼ ⋆, γ ⟼ ⋆), ⋆) = ((α ⟼ ⋆, β ⟼ ⋆, γ ⟼ x), ⋆))$

We also define a component that "produces" any output ("information gain"):

```diagram
title: The $¡$ component.
basename: produce

α:0 ┌───┐ β:A
────┤ ¡ ├────
    └───┘
```

$0$ is a type with no value, hence $α$ is always empty. For each input (but
there will never be any), $¡$ "consumes" it and produces a $A$ value out of thin
air.

```lemma
name: prod-cocart

Sum composition (with $▽$, $inl$, $inr$, $¡$) forms a cocartesian category.
```

From cocartesian category, we get the following identities ($f$ and $g$ are not
related to previously defined components with the same names):

- $f + g = (f ; inl) ▽ (g ; inr)$
- $inl ; (f ▽ g) = f$
- $inr ; (f ▽ g) = g$
- $(inl ; h) ▽ (inr ; h) = h$
- $inl ▽ inr = id$
- $(h + k) ; (f ▽ g) = (h ; f) ▽ (k ; g)$
- $id + id = id$
- $(h + k) ; (f + g) = (h ; f) + (k ; g)$
- $(f ▽ g) ; h = (f ; h) ▽ (g ; h)$


### Relation between product and sum

There is an exchange identity relating split ($△$) and join ($▽$):

$(f △ g) ▽ (h △ j) = (f ▽ h) △ (g ▽ j)$

```lemma
name: dist

Product and sum composition form a distributive category.
```

$undistl: (A × B) + (A × C) → A × (B + C)$

$undistl = (exl ▽ exl) △ (exr + exr) = (id × inl) ▽ (id × inr)$

```diagram
title: The $undistl$ component.
basename: undistl

     undistl
   ┌─────────┐
 A │         │
───┤         │ A
 B │         ├───
───┤         │
   │         │
 + │         │ B
   │         ├───
 A │         │ +
───┤         │ C
 C │         ├───
───┤         │
   └─────────┘
```

It is also possible to define a component that distributes product on sum, but
not purely in terms of composition and components defined so far:

$distl: A × (B + C) → (A × B) + (A × C)$

```diagram
title: The $distl$ component.
basename: distl

      distl
   ┌─────────┐ 
   │         │ A 
 A │         ├───
───┤         │ B 
   │         ├───
   │         │   
 B │         │ + 
───┤         │   
 + │         │ A 
 C │         ├───
───┤         │ C 
   │         ├───
   └─────────┘
```


### Feedback

Up to this point, in the diagrams we saw the values flow from left to right. We
now define two components that reverse the flow:

```diagram
title: The $η$ component.
basename: eta

    ┌─────┐ β:A
α:0 │     ├────
────┤  η  │  +
    │     ├────
    └─────┘ γ:-A
```

$-A$ denotes the type of values of $A$ flowing in reverse direction. Thus, $η$
consumes on wire $γ$ and produces on wire $β$.

$η = ({α, γ}, {β}, ⋆, up)$ where

$up(_, (α ⟼ ⋆, β ⟼ ⋆, γ ⟼ x), ⋆) = ((α ⟼ ⋆, β ⟼ x, γ ⟼ ⋆), ⋆)$

Seen as function, $η$ has the signature $0 → A + -A$.

The mirror is $ε: A + -A → 0$ with the obvious behavior:


```diagram
title: The $ε$ component.
basename: epsilon

β:A ┌─────┐
────┤     │ α:0
 +  │  ε  ├────
────┤     │
γ:-A└─────┘
```

```lemma
name: compact

Sum composition with $η$ and $ε$ forms a compact closed category.
```

Compact closed category allows one to construct "traces", or loops.

$trace(f): A → B = inr0 ; id + η ; assocl ; f + id ; assocr ; id + ε ; exr0$ where:

- $f: A + C → B + C$
- $inr0: A → A + 0$
- $exr0: B + 0 → B$
- $assocl: A + (C + -C) → (A + C) + -C$
- $assocr: (B + C) + -C → B + (C + -C)$


Making types explicit:

```diagram
title: $trace$ implementation.
basename: trace-implementation

  inr0     id+η          assocl          f+id          assocr          id+ε     exr0
A ---> A+0 ---> A+(C+-C) -----> (A+C)+-C ---> (B+C)+-C -----> B+(C+-C) ---> B+0 ---> B
```

As a diagram ($id$ and $assoc*$ omitted):

```diagram
title: The $trace(f)$ component.
basename: trace1

                             trace(f)
 ┌────────────────────────────────────────────────────────────┐
 │ ┌──────┐       A        ┌───────┐        B        ┌──────┐ │
 │ │ inr0 ├────────────────┤   f   ├─────────────────┤ exr0 │ │
A│ │      │ +            + │       │ +            +  │      │ │B   
─┼─┤      │   ┌───────┐  C │       │ C  ┌───────┐    │      ├─┼─
 │ │      │ 0 │   η   ├────┤       ├────┤   ε   │ 0  │      │ │
 │ │      ├───┤       │  + └───────┘ +  │       ├────┤      │ │
 │ └──────┘   │       ├─────────────────┤       │    └──────┘ │
 │            └───────┘       -C        └───────┘             │
 └────────────────────────────────────────────────────────────┘
```

The graphical language of string diagrams further simplifies the above diagram
to:

```diagram
title: The $trace(f)$ component (string diagram 1).
basename: trace2

                            trace(f)
 ┌────────────────────────────────────────────────────────────┐
A│              A          ┌───────┐          B               │B
─┼────┬────────────────────┤   f   ├─────────────────┬────────┼─
 │    │   +            +   │       │   +         +   │        │    
 │    │                C   │       │   C             │        │ 
 │    │   0       ┌────────┤       ├────────┐    0   │        │
 │    └───────────┤    +   └───────┘   +    ├────────┘        │
 │                └─────────────────────────┘                 │
 │                            -C                              │
 └────────────────────────────────────────────────────────────┘
```

Or even:

```diagram
title: The $trace(f)$ component (string diagram 2).
basename: trace3

                            trace(f)
 ┌────────────────────────────────────────────────────────────┐
A│                     A   ┌───────┐   B                      │B
─┼─────────────────────────┤   f   ├──────────────────────────┼─
 │                     +   │       │   +                      │    
 │                     C   │       │   C                      │ 
 │                ┌────────┤       ├────────┐                 │
 │                │      + └───────┘ +      │                 │
 │                └─────────────────────────┘                 │
 │                            -C                              │
 └────────────────────────────────────────────────────────────┘
```

Some identities can be represented graphically. For instance, "zig-zags" can be
straightened:

```diagram
title: The first zig-zag equation.
basename: zig-zag-1

  A
─────┐
  -A │       A
┌────┘  =  ─────
│
└─────
  A
```

As a formula (with $η': 0 → -A + A$, $exl0: 0 + A → A$):

$inr0 ; id + η' ; assocl ; ε +id ; exl0  =  id$

A mirror version also exists:

```diagram
title: The second zig-zag equation.
basename: zig-zag-2

  -A
┌─────
│ A         -A
└────┐  =  ─────
     │
─────┘
  -A
```



# References

- Calculating functional programs, Gibbons, 2002

- Compiling to Categories, Elliott, 2017

- A computational interpretation of compact closed categories, Chen and Sabry,
  2021

- A survey of graphical languages for monoidal categories, Selinger, 2009
