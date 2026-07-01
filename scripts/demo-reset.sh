#!/bin/bash
# Resets the demo state for the next run
set -e

echo "=== Resetting Petclinic Demo ==="

# Close any open PRs on the demo branch
gh pr close demo/search-owners 2>/dev/null || true

# Switch to main and clean up
git checkout main
git pull

# Delete demo branch locally and remotely
git branch -D demo/search-owners 2>/dev/null || true
git push origin --delete demo/search-owners 2>/dev/null || true

echo "=== Demo reset complete. Ready for next run. ==="
