#!/bin/bash
# Fixes the SQL injection vulnerability
set -e

echo "=== Fixing Petclinic Vulnerability ==="

git checkout demo/search-owners

# Remove the vulnerable code (last 7 lines) and add the fix
# First, remove the appended vulnerable code
head -n -7 src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java > tmp_controller.java
mv tmp_controller.java src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java

# Add the fixed version
cat >> src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java << 'JAVAEOF'

@GetMapping("/api/owners/search")
@ResponseBody
public List<Owner> searchOwners(@RequestParam String query) {
    return this.owners.findByLastName(query);
}
JAVAEOF

git add src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java
git commit -m "Fix SQL injection - use Spring Data repository"
git push

echo ""
echo "=== Fix pushed. Watch the pipeline re-run in Harness. ==="
