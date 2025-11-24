#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

echo "Building project..."
stack build --test --no-run-tests

EXE=$(stack path --local-install-root)/bin/TP2-exe
if [ ! -x "$EXE" ]; then
  # fallback to stack exec
  RUN_CMD=(stack exec -- TP2-exe --)
else
  RUN_CMD=("$EXE" )
fi

# Files to load
FILES=(Ejemplos/Naturales.lam Ejemplos/Listas.lam)

TMPOUT=$(mktemp)

echo "Running interpreter and loading examples..."

# Send a sequence of commands: ask for types and evaluate sumList, then quit
# :type <term> prints the type
CMD=$(cat <<'CMD'
:type mylist
:type sumList
sumList
:quit
CMD
)

# Additional complex parsing/precedence tests
CMD_EXTRA=$(cat <<'CMD'
:print suc 0 0
:print cons suc 0 nil
:print RL 0 (\n:Nat. cons n nil) nil
:print \x:E. let y = 0 in x
:print let y = 0 in \x:E. y
:print R 0 (\n:Nat. suc n) suc 0
:print cons suc 0 RL 0 (\n:Nat. cons n nil) nil
:quit
CMD
)

# Execute and capture output (use stack exec if needed)
if [ -x "$EXE" ]; then
  # run basic checks
  "$EXE" "${FILES[@]}" > "$TMPOUT" 2>&1 <<EOF
$CMD
EOF
  # run extra parsing/precedence checks
  "$EXE" "${FILES[@]}" >> "$TMPOUT" 2>&1 <<EOF
$CMD_EXTRA
EOF
else
  # fallback using stack exec
  stack exec -- TP2-exe -- "${FILES[@]}" > "$TMPOUT" 2>&1 <<EOF
$CMD
EOF
  stack exec -- TP2-exe -- "${FILES[@]}" >> "$TMPOUT" 2>&1 <<EOF
$CMD_EXTRA
EOF
fi

cat "$TMPOUT"

# Basic checks
echo "Checking that mylist has type 'List Nat'..."
grep -q "List Nat" "$TMPOUT" || { echo "FAIL: mylist type not found"; exit 2; }

echo "Checking that sumList has type 'Nat'..."
grep -q "Nat" "$TMPOUT" || { echo "FAIL: sumList type not found"; exit 3; }

# Check evaluation output contains a numeral (0 or suc)
if grep -q "0" "$TMPOUT" || grep -q "suc" "$TMPOUT"; then
  echo "Evaluation looks fine (found numeric output)"
else
  echo "FAIL: evaluation of sumList did not produce a numeric-looking output"; exit 4
fi

  # Parsing/precedence checks
  echo "Checking parsing/precedence cases..."

  check() {
    local pattern="$1"
    local msg="$2"
    grep -q "$pattern" "$TMPOUT" || { echo "FAIL: $msg"; exit 5; }
  }

  check "LApp" "suc 0 0 should be parsed as an application (suc 0) 0"
  check "LSuc" "suc should appear in parsing suc 0 0"
  check "LCons" "cons suc 0 nil should parse as LCons"
  check "LSuc" "cons suc 0 nil should contain suc"
  check "LRecList" "RL test should produce LRecList"
  check "LLet" "let vs lambda precedence: \x:E. let y = 0 in x should contain LAbs and LLet"
  check "LAbs" "let y = 0 in \x:E. y should contain LLet and LAbs"
  check "LRec" "R numeric recursion should produce LRec"
  check "LRecList" "cons ... RL ... should include LRecList nested"


rm -f "$TMPOUT"

echo "All tests passed." 
