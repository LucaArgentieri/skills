#!/usr/bin/env bash
# Run every test in this folder. Usage: bash tests/run.sh
cd "$(dirname "$0")/.."
status=0
for t in "python3 tests/lint-skills.py" "bash tests/detect-multiplexer.test.sh" "bash tests/tmux-e2e.test.sh"; do
  echo "== $t"
  $t || status=1
done
[ "$status" -eq 0 ] && echo "== all tests passed" || echo "== some tests failed"
exit "$status"
