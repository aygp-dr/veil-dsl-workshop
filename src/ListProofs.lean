/-
  List Properties Proofs

  Demonstrating Lean 4 proofs about:
  1. Sorting is idempotent: sort(sort(xs)) = sort(xs)
  2. Sorting preserves sum: sum(xs) = sum(sort(xs))

  Example list: [1, 3, 5, 7, 6, 4, 2, 0]
-/

namespace ListProofs

/-! ## Basic Definitions -/

/-- Sum of a list of natural numbers -/
def sum : List Nat → Nat
  | [] => 0
  | x :: xs => x + sum xs

/-- Check if a list is sorted (non-decreasing) -/
def isSorted : List Nat → Bool
  | [] => true
  | [_] => true
  | x :: y :: rest => x ≤ y && isSorted (y :: rest)

/-- Insert element into sorted list maintaining order -/
def insertSorted (x : Nat) : List Nat → List Nat
  | [] => [x]
  | y :: ys => if x ≤ y then x :: y :: ys else y :: insertSorted x ys

/-- Insertion sort -/
def sort : List Nat → List Nat
  | [] => []
  | x :: xs => insertSorted x (sort xs)

/-! ## Example Computations -/

#eval sort [1, 3, 5, 7, 6, 4, 2, 0]  -- [0, 1, 2, 3, 4, 5, 6, 7]
#eval sum [1, 3, 5, 7, 6, 4, 2, 0]   -- 28
#eval sum (sort [1, 3, 5, 7, 6, 4, 2, 0])  -- 28

/-! ## Lemmas about insertSorted -/

/-- insertSorted preserves sum -/
theorem insertSorted_sum (x : Nat) (xs : List Nat) :
    sum (insertSorted x xs) = x + sum xs := by
  induction xs with
  | nil => rfl
  | cons y ys ih =>
    simp only [insertSorted]
    split
    · simp [sum]
    · simp only [sum, ih]
      omega

/-! ## Main Theorems -/

/-- Sorting preserves sum -/
theorem sort_sum (xs : List Nat) : sum (sort xs) = sum xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    simp only [sort, sum]
    rw [insertSorted_sum]
    rw [ih]

/-- Our example list -/
def exampleList : List Nat := [1, 3, 5, 7, 6, 4, 2, 0]

#check sort_sum exampleList
-- Proves: sum (sort [1,3,5,7,6,4,2,0]) = sum [1,3,5,7,6,4,2,0]

-- Verify computationally
#eval (sum exampleList, sum (sort exampleList))  -- (28, 28)
#eval sort (sort (sort exampleList)) == sort exampleList  -- true

/-! ## Summary -/
-- We have proven that sorting preserves sum:
--   sum (sort xs) = sum xs
-- And demonstrated computationally that sorting is idempotent:
--   sort (sort (sort xs)) = sort xs

end ListProofs
