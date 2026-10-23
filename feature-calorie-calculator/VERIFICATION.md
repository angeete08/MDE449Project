# Isolation verification

## Branding update — October 23, 2026

Hero paint positioning revision: rotated only the hero background 10 degrees counterclockwise and shifted it 12 pixels left, preserving its horizontal mirroring. Browser preview confirmed the athlete and upper-left wordmark stayed fixed. Source checks and all 25 feature tests passed; parent/dev file checksum manifests matched.

Background contrast revision: mirrored both paint textures left-to-right about the vertical axis. The hero paint and athlete use separate CSS layers so only the texture flips; the original athlete and wordmark keep their orientation. Browser inspection and the saved preview confirmed the result. All 25 isolated tests and the 20-file source check passed, and parent/dev checksum manifests matched.

Uneven brush-color revision: replaced the vector paint backgrounds with an original transparent raster texture following the user's brush-swash references. The final page shows directional bristle scratches, broken edges, small spatters, patchy paint coverage, and irregular olive/forest-green color variation behind both original brand elements. Browser inspection confirmed the background has no rectangular backdrop. All 25 feature tests and the source check passed; only CSS/assets and documentation changed in this revision.

Paint-reference revision: the wordmark now uses a separate slanted brush-smear asset. The hero background uses soft asymmetric paint pools and hanging drips, replacing the pointed silhouette and rectangular stamp impression. Detached spots remain. Browser inspection confirmed the final treatment; 20 source files and all 25 isolated tests passed again.

Irregularity revision: replaced the rounded paint outline with an asymmetric splashed silhouette, jagged extensions, longer drips, and visible detached paint spots. Browser preview confirmed these around both the wordmark and hero logo. The source check passed 20 files, all 25 isolated tests passed, and parent/dev checksum manifests remained identical.

Graffiti background revision: both the wordmark and hero logo use a shared local SVG spray-painted shape with irregular edges, overspray speckles, layered strokes, and drips. Source checks and all 25 isolated tests passed again. Parent/dev file checksums remained identical. Original branding artwork and placements are preserved.

Final layout revision: the header contains only the Logo 1 wordmark, with the full capital S curve visible. Logo 2 replaces the right-side hero illustration. Browser verification confirmed both placements; the preview at `.jac/qa/branding-preview.jpg` shows this final layout. The repeated source check passed 20 files, all 25 isolated tests passed, and parent/dev file checksum manifests matched.

Fetched the group repository and compared the local feature app with published `calorie-calculator` commit `69fe904`. Its application source and datasets were already current; the feature's isolated project name, explicit entry point, and ports were retained. On branch `feature/calorie-calculator`, the header now shows the athlete from `logos` branch Logo 2 and the STRIDE lettering under Logo 1 (`4c8ab57`). Original TIFF artwork was converted to transparent PNG without redrawing or cropping its canvas; CSS selects the displayed regions.

`jac run --show` resolved this folder's own entry point before execution. `jac check . --nowarn` passed for 20 source files and the six explicit feature test files passed all 25 tests with serial workers. Browser inspection confirmed the artwork loads in the header. Preview: `.jac/qa/branding-preview.jpg`. Installed Jac remains 0.37.11; the target is 0.37.21.

All 16,391 regular files outside this feature folder (excluding Git internals) had identical SHA-256 manifests before and after verification. Local and remote main/dev refs and the remote logos ref were unchanged. No commit or push was performed; existing staged and unstaged work was preserved.

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
