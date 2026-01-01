/-
  List Properties Proofs

  Demonstrating Lean 4 proofs about:
  1. Sorting is idempotent: sort(sort(xs)) = sort(xs)
  2. Sorting preserves sum: sum(xs) = sum(sort(xs))

  Example list: [1, 3, 5, 7, 6, 4, 2, 0]
-/

-- Use standard library
import Std.Data.List.Basic

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
  | nil => simp [insertSorted, sum]
  | cons y ys ih =>
    simp only [insertSorted]
    split
    · simp [sum]
    · simp [sum, ih]
      omega

/-- insertSorted into sorted list produces sorted list -/
theorem insertSorted_sorted (x : Nat) (xs : List Nat) (h : isSorted xs = true) :
    isSorted (insertSorted x xs) = true := by
  induction xs with
  | nil => simp [insertSorted, isSorted]
  | cons y ys ih =>
    simp only [insertSorted]
    split
    case isTrue hle =>
      simp only [isSorted]
      simp [hle, h]
    case isFalse hgt =>
      simp only [isSorted] at h ⊢
      cases ys with
      | nil =>
        simp [insertSorted, isSorted]
        omega
      | cons z zs =>
        simp only [isSorted, Bool.and_eq_true] at h
        have ⟨hyz, hrest⟩ := h
        simp only [insertSorted]
        split
        case isTrue hxz =>
          simp [isSorted, hyz, hxz]
        case isFalse hxz =>
          have ih' := ih (by simp [isSorted, hrest])
          simp only [isSorted, Bool.and_eq_true]
          constructor
          · exact hyz
          · simp only [insertSorted] at ih'
            split at ih' <;> exact ih'

/-! ## Main Theorems -/

/-- Sorting produces a sorted list -/
theorem sort_sorted (xs : List Nat) : isSorted (sort xs) = true := by
  induction xs with
  | nil => simp [sort, isSorted]
  | cons x xs ih =>
    simp only [sort]
    exact insertSorted_sorted x (sort xs) ih

/-- Sorting preserves sum -/
theorem sort_sum (xs : List Nat) : sum (sort xs) = sum xs := by
  induction xs with
  | nil => simp [sort, sum]
  | cons x xs ih =>
    simp only [sort, sum]
    rw [insertSorted_sum]
    rw [ih]

/-- Sorting is idempotent: sorting a sorted list gives the same list -/
theorem insertSorted_sorted_eq (x : Nat) (xs : List Nat) (h : isSorted (x :: xs) = true) :
    insertSorted x xs = x :: xs := by
  cases xs with
  | nil => simp [insertSorted]
  | cons y ys =>
    simp only [isSorted, Bool.and_eq_true] at h
    simp only [insertSorted]
    split
    case isTrue => rfl
    case isFalse hgt => omega

/-- Helper: sorting a sorted list gives the same list -/
theorem sort_sorted_eq (xs : List Nat) (h : isSorted xs = true) : sort xs = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    simp only [sort]
    have hsorted_tail : isSorted xs = true := by
      cases xs with
      | nil => rfl
      | cons y ys =>
        simp only [isSorted, Bool.and_eq_true] at h
        exact h.2
    rw [ih hsorted_tail]
    exact insertSorted_sorted_eq x xs h

/-- Main theorem: sort(sort(xs)) = sort(xs) -/
theorem sort_idempotent (xs : List Nat) : sort (sort xs) = sort xs := by
  apply sort_sorted_eq
  exact sort_sorted xs

/-! ## Concrete Example -/

/-- Our example list -/
def exampleList : List Nat := [1, 3, 5, 7, 6, 4, 2, 0]

#check sort_sum exampleList
-- Proves: sum (sort [1,3,5,7,6,4,2,0]) = sum [1,3,5,7,6,4,2,0]

#check sort_idempotent exampleList
-- Proves: sort (sort [1,3,5,7,6,4,2,0]) = sort [1,3,5,7,6,4,2,0]

-- Verify computationally
#eval (sum exampleList, sum (sort exampleList))  -- (28, 28)
#eval sort (sort (sort exampleList)) == sort exampleList  -- true

end ListProofs
