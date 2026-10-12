# Stride calorie calculator

This folder is a self-contained copy of the Stride app with the calorie calculator beneath the existing food advice. Its source, styles, configuration, tests, and USDA dataset are all local to this folder. It does not import files from the parent project or require changes to sibling folders.

Use Jac **0.37.21**, as pinned in `jac.toml`. From this folder:

```sh
jac install
jac run
```

Open the address printed by Jac (normally http://localhost:8000). If another app uses that port, run `jac run --port 8300` instead.

Verify from this folder:

```sh
jac check
jac test
```

`main.jac` registers the app and calorie endpoints. `frontend.jac` places `feature-calorie-calculator.jac` below meal advice. `calorie_data.jac` reads `data/foundation_foods_2025-12-18.json`; `recipe_calories.jac` provides automatic lookup and ingredient estimates. `frontend.css` and `global.css` provide the styling. `planner_tests.jac`, `calorie_tests.jac`, and `recipe_tests.jac` cover the existing app and this feature.

Enter a food or recipe name and click **Find calories**. The best name match appears immediately; alternative matches are collapsed under **Not the right match?** There is no required selection screen. Typos and word-order changes are supported, but generic names remain ambiguous: review the displayed preparation and variety.

Food calories equal kcal per 100 g × grams / 100, rounded to one decimal. The lookup prefers Atwater specific energy (2048), then general energy (2047), then legacy energy (1008), using only kcal entries. The 365-food USDA snapshot does not cover every ingredient or branded product. Missing energy data is never treated as zero. See [USDA's Foundation Foods documentation](https://fdc.nal.usda.gov/Foundation_Foods_Documentation/) for the nutrient basis.

TheMealDB has recipe names, ingredients, and measures, **not calorie labels**. An exact base-name USDA equivalent may provide a clearly labeled approximation (for example, commercial hummus for the Hummus recipe). Otherwise the calculator suggests ingredient matches and lets the user supply weights. Only explicit g/kg/oz/lb measures prefill weights; cups, counts, and “to taste” remain blank. Review or change a match in its expandable row. When USDA lacks a suitable ingredient, enter kcal per 100 g from the package label; these entries are identified in the breakdown. All ingredients and weights must be supplied before a total is returned. Recipe results show total ingredient calories and calories per user-entered serving, not calories per cooked gram. Cooking losses, absorption, and recipe yield are not modeled.

## Fitted name model

`name_model.jac` implements a word and character 3/4-gram TF-IDF retrieval model in Jac. `train_matcher.jac` fits inverse document frequency weights and normalized document vectors using **790 TheMealDB recipe titles and 365 USDA food names**. The fitted artifact is bundled at `data/name_matcher.json` (1,155 titles, 9,314 learned term weights). Name normalization, token-coverage checks, exact-name preference, and modifier penalties rerank candidates. Similarity scores are not probabilities. This is an unsupervised name-retrieval model, **not a neural model or a trained calorie predictor**; there are no recipe calorie labels to train such a predictor.

The app searches the bundled corpus offline. It does not make a live API request for each query. Refresh and retrain explicitly from this folder:

```sh
jac run --no-serve refresh_recipes.jac
jac run --no-serve train_matcher.jac
jac run --no-serve evaluate_matcher.jac
```

Restart `jac run` after refreshing or training to clear in-memory model/data caches. Refreshing uses 26 documented first-letter requests to [TheMealDB V1 API](https://www.themealdb.com/api.php), with the public educational test key `1`; it writes a new snapshot only after every request succeeds. The snapshot keeps only IDs, names, ingredient names, and measures. The API's terms for public app-store release require a supporter key; this integration targets the educational project.

`data/matching_evaluation.json` records a small development benchmark: 8/9 expected first matches. The broad query “chicken curry” returns “Nutty Chicken Curry,” illustrating that an underspecified name cannot identify an exact recipe. These examples are regression checks, not an independent accuracy study or evidence of calorie accuracy. Additional tests cover singular ingredient names, missing-energy foods, invalid weights, recipe totals, manual labels, and missing ingredients.

The calculator leaves the user-entered daily target unchanged. The existing workout and meal advice behavior is included in this standalone copy; future changes in other project folders are not automatically synchronized here.
