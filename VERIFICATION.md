# Isolation verification

Verified on October 12, 2026 with installed Jac 0.37.11. The project remains pinned to 0.37.21; these results do not verify that version.

Before executing tests, the working directory was confirmed as this folder, `jac run --show` resolved this folder's `main.jac`, and test collection listed only the six explicitly requested feature test files. The feature uses its own `.jac/venv`, build/cache/database directory, and project name `stride-calorie-calculator-feature`. Browser verification used explicit frontend port 8300 and backend port 8301.

- `jac check . --nowarn`: 20 files passed.
- `jac check planner_tests.jac --nowarn`: adjusted test passed its source check.
- `jac test --jobs 0 planner_tests.jac calorie_tests.jac recipe_tests.jac web_nutrition_tests.jac nutrition_agent_tests.jac local_calories_tests.jac`: 25 tests passed.
- Browser: local mode loaded with the portion control collapsed at 100 g. Qwen3 1.7B returned 220 kcal for chicken curry at 100 g; changing the portion to 250 g returned 550 kcal.
- SHA-256 manifests of all 16,391 regular files outside this feature folder (excluding Git internals) matched before test execution and after tests/browser startup. This included parent and dev source and runtime files. No parent/dev tests were executed.

The initial test run had one failure because two uncontrolled random meal selections matched. Only the feature's copied planner test was changed to control its random draws; the parent and dev planner files and tests were untouched.

The root's calculator imports and rendering were removed as part of extracting the feature. Fitness planning, user-entered calorie targets, and meal ideas remain in the root. Its running server may still show an older in-memory build until its owner restarts it.

Model estimates are approximate and this browser check establishes execution/scaling, not nutrition accuracy.
