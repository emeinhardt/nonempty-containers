default: cbuild

set ignore-comments := true

# NOTE all commands are executed as though from a shell at the project root, 
# regardless of where you may be in a shell inside the project when you invoke
# a recipe.

alias c := cbuild
alias t := ctest
alias d := doc
alias n := nbuild
alias nt := tbuild

cbuild:
  cabal build all

ctest:
  cabal test all

doc:
  cabal haddock all

nbuild:
  nix build

tbuild:
  nix build .#nonempty-containers-test
