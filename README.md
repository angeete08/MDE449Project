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

`main.jac` registers the app and calorie endpoints. `frontend.jac` places `feature-calorie-calculator.jac` below meal advice. `calorie_data.jac` reads `data/foundation_foods_2025-12-18.json`. `frontend.css` and `global.css` provide the styling. Both `planner_tests.jac` and `calorie_tests.jac` are included.

Search by food name, select its preparation, and enter the edible portion weight in grams. Calories equal kcal per 100 g × grams / 100, rounded to one decimal. The lookup prefers Atwater specific energy (2048), then general energy (2047), then legacy energy (1008), using only kcal entries. Foods without energy data are marked unavailable, never treated as zero. The supplied dataset contains 365 foods and does not cover every food or branded product. It requires no external request or API key. See [USDA's Foundation Foods documentation](https://fdc.nal.usda.gov/Foundation_Foods_Documentation/) for the nutrient basis.

The calculator leaves the user-entered daily target unchanged. The existing workout and meal advice behavior is included in this standalone copy; future changes in other project folders are not automatically synchronized here.
