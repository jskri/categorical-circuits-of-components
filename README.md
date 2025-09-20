# Categorical circuits of components

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


# Files

The main file is
[categorical-circuits-of-components.md](./categorical-circuits-of-components.md).

A PDF can be found in the releases.
