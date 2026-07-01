#!/bin/bash
# Creates a PR with a SQL injection vulnerability for the demo
set -e

echo "=== Starting Petclinic Demo ==="

# Clean up any previous demo branch
git checkout main
git pull
git branch -D demo/search-owners 2>/dev/null || true
git push origin --delete demo/search-owners 2>/dev/null || true

# Create fresh branch
git checkout -b demo/search-owners

# Add vulnerable search endpoint to OwnerController
cat >> src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java << 'JAVAEOF'

// Quick search endpoint for the frontend team
@GetMapping("/api/owners/search")
@ResponseBody
public List<Owner> searchOwners(@RequestParam String query, jakarta.persistence.EntityManager em) {
    return em.createQuery("SELECT o FROM Owner o WHERE o.lastName LIKE '%" + query + "%'", Owner.class)
             .getResultList();
}
JAVAEOF

git add src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java
git commit -m "Add owner search API endpoint"
git push -u origin demo/search-owners
gh pr create --title "Add owner search API endpoint" \
  --body "Quick search endpoint for the frontend team." \
  --base main --head demo/search-owners

echo ""
echo "=== PR created. Switch to Harness UI to watch the review. ==="
