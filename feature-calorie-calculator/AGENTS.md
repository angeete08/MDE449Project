# Stride development

All application logic, frontend components and tests are written in Jac. Do not add handwritten JavaScript or Python. CSS and TOML are supporting assets. Consult `jac guide jac-essentials`, `jac guide jac-fullstack-patterns`, and the guide named by compiler diagnostics before changing Jac source.

The project targets Jac 0.37.21. Teammates run `jac install` and `jac run` from this folder. Run `jac check`, `jac test`, and browser checks before handoff. Preserve completed workouts when processing feedback; validate profiles on the server; keep calorie targets user-entered. Do not claim live AI, medical assessment, teammate review or user testing unless implemented and verified.

## Calculator isolation

Before tests, confirm the working directory is this `feature-calorie-calculator` folder and `jac run --show` resolves its own `main.jac`. All calculator source, datasets, evaluation outputs, and runtime files must stay here. Do not import parent or dev modules, reuse their `.jac` directories, run feature files through the parent project, use `--takeover`, or stop unrelated servers. Use explicit feature test files and serial workers. Browser checks use reserved ports 8300 and 8301. Compare parent and dev file checksums before and after verification; stop if project resolution or imports escape this folder. Never run calculator tests from the repository root.
