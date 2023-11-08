# `nonempty-containers`

This is a fork of 
[nonempty-containers](https://github.com/mstksg/nonempty-containers) 
motivated by solving two problems

 1. A large dependency footprint with attendant long compile times, mainly due 
    to `aeson` instances and test-only dependency `hedgehog`.
 2. Maintenance for compatibility with changes to `semigroupoids` and 
    `foldable1-classes-compat` due to the merger of `Foldable1` and friends in 
    `base-4.18`+.

`nonempty-containers` hasn't been updated in two years at the time of writing, 
so I decided to fork the package to address both concerns.

Changes:

 1. I have split the package into `nonempty-containers-alt` and 
    `nonempty-containers-test`.
 2. I have disabled `aeson` by default. As any downstream user will have to 
    opt in to using this package, I don't see forcing any `aeson` instance 
    user into passing a flag as that big of a concern.
 3. Because I do not use `hpack` or `stack`, I have also dropped `hpack` and 
    `stack` config files; pull requests are welcome to restore functionality 
    related to either.


# Original README

Efficient and optimized non-empty (by construction) versions of types from
*[containers][]*. Inspired by *[non-empty-containers][]* library, except
attempting a more faithful port (with under-the-hood optimizations) of the full
*containers* API.  Also contains a convenient typeclass abstraction for
converting between non-empty and possibly-empty variants, as well as pattern
synonym-based conversion methods.

[containers]: http://hackage.haskell.org/package/containers
[non-empty-containers]: http://hackage.haskell.org/package/non-empty-containers

Non-empty *by construction* means that the data type is implemented using a
data structure where it is structurally impossible to represent an empty
collection.

Unlike similar packages (see below), this package is defined to be a
*drop-in replacement* for the *containers* API in most situations.  More or
less every single function is implemented with the same asymptotics and
typeclass constraints.  An extensive test suite (with 457 total tests) is
provided to ensure that the behavior of functions are identical to their
original *containers* counterparts.

Care is also taken to modify the interface of specific functions to reflect
non-emptiness and emptiness as concepts, including:

1.  Functions that might return empty results (like `delete`, `filter`) return
    possibly-empty variants instead.

2.  Functions that totally partition a non-empty collection (like `partition`,
    `splitAt`, `span`) would previously return a tuple of either halves:

    ```haskell
    mapEither :: (a -> Either b c) -> Map k a -> (Map k b, Map k c)
    ```

    The final result is always a total partition (every item in the original
    map is represented in the result), so, to reflect this, [`These`][these] is
    returned instead:

    ```haskell
    data These a b = This  a
                   | That    b
                   | These a b

    mapEither :: (a -> Either b c) -> NEMap k a -> These (NEMap k b) (NEMap k c)
    ```

    This preserves the invariance of non-emptiness: either we have a non-empty
    map in the first camp (containing all original values), a non-empty map in
    the second camp (containing all original values), or a split between two
    non-empty maps in either camp.

    [these]: https://hackage.haskell.org/package/these

3.  Typeclass-polymorphic functions are made more general (or have more general
    variants provided) whenever possible.  This means that functions like
    `foldMapWithKey` are written for all `Semigroup m` instead of only `Monoid
    m`, and `traverseWithKey1` is provided to work for all `Apply f` instances
    (instead of only `Applicative f` instances).

    `Foldable1` and `Traversable1` instances are also provided, to provide
    `foldMap1` and `traverse1`.

4.  Functions that can "potentially delete" (like `alter` and `updateAt`)
    return possibly-empty variants.  However, alternatives are offered
    (whenever not already present) with variants that disallow deletion,
    allowing for guaranteed non-empty maps to be returned.

Contains non-empty versions for:

*   `Map`
*   `IntMap`
*   `Set`
*   `IntSet`
*   `Sequence`

A typeclass abstraction (in *Data.Containers.NonEmpty*) is provided to allow
for easy conversions between non-empty and possibly-empty variants.  Note that
`Tree`, from *Data.Tree*, is already non-empty by construction.

Similar packages include:

*   [non-empty-containers][]: Similar approach with similar data types, but API
    is limited to a few choice functions.
*   [nonemptymap][]: Another similar approach, but is limited only to `Map`,
    and is also not a complete API port.
*   [non-empty-sequence][]: Similar to *nonemptymap*, but for `Seq`.  Also not
    a complete API port.
*   [non-empty][]: Similar approach with similar data types, but is meant to be
    more general and work for a variety of more data types.
*   [nonempty-alternative][]: Similar approach, but is instead a generalized
    data type for all `Alternative` instances.

[nonemptymap]: https://hackage.haskell.org/package/nonemptymap
[non-empty-sequence]: https://hackage.haskell.org/package/non-empty-sequence
[non-empty]: https://hackage.haskell.org/package/non-empty
[nonempty-alternative]: https://hackage.haskell.org/package/nonempty-alternative

Currently not implemented:

*   Extended merging functions.  However, there aren't too many benefits to be
    gained from lifting extended merging functions, because their
    emptiness/non-emptiness guarantees are difficult to statically conclude.
*   Strict variants of Map functions.  This is something that I wouldn't mind,
    and might add in the future.  PR's are welcomed!
