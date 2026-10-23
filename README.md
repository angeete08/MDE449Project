# Stride

The root application contains fitness planning and meal ideas. Its calorie target remains user-entered. The calorie calculator is a separate app in [feature-calorie-calculator](feature-calorie-calculator/README.md); its source, datasets, and tests are contained there. `MDE449Project-dev/` is a separate development project.

Use Jac 0.37.21 as pinned in `jac.toml`. Run the root app from this folder with `jac install` and `jac run`.

To run the calorie calculator:

```sh
cd /Users/zeta/Documents/MDE449Project/feature-calorie-calculator
jac install
jac run
```

Calculator verification commands and isolation rules are documented in the feature README. Run root checks explicitly with `jac check main.jac frontend.jac planner.jac planner_tests.jac` and root tests with `jac test planner_tests.jac`, so nested apps are not collected.
