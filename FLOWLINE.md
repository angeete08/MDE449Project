# MVP review handoff

Group 10 repository: https://github.com/angeete08/MDE449Project
Course reference: https://github.com/marsninja/CSE449-F26

## Artifacts and status

- [Issue #1 — Finalize Project Idea](https://github.com/angeete08/MDE449Project/issues/1): existing group scope issue, open.
- [Issue #2 — Implement five-feature fitness MVP in Jac](https://github.com/angeete08/MDE449Project/issues/2): acceptance criteria and implementation review, open.
- Branch: `feat/jac-fitness-mvp`, created from `dev`. Use the PR linked in the weekly progress slide for review into dev; teammate review and merge remain pending.
- Implementation: Jac UI, server rules, generated RPC, saved-state validation, browser persistence and export; deterministic planning and curated meals.
- Validation on October 5: fresh-directory `jac install` and bare `jac run`, no compiler errors, five passing Jac tests including 648 profile combinations; browser generation, feedback, refresh, JSON download, and equipment/diet change checked. Teammate usability and Linux/WSL execution remain pending.

## Flowline

Scope → Codex-assisted implementation → code/content oversight → automated and browser validation → teammate review → dev integration → main release.

This describes the work's handoff stage, not a claimed entry in the team's Flowline tool. The team still needs to select the reviewer and record the actual handoff. Oversight includes checking exercise rules, approximate meal calories, input validation, saved-state validation, preservation of completed workouts, and truthful labeling of deterministic behavior. Live model integration requires a separate proposal and evaluation.
