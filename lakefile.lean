import Lake
open Lake DSL

package «veil-dsl-workshop» where
  version := v!"0.1.0"

@[default_target]
lean_lib «ListProofs» where
  srcDir := "src"
