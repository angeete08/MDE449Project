"""Preview and explicitly save a future routine; never replace a saved week."""
import json;
import from datetime { date, timedelta }
import from planner { make_state, date_plan, monday, validate_state }
import from routine_rules { routine_week }
import from .coach_profile { CoachProfile, validate_profile }
import from services.stride { require_profile, get_plan_state, planner_profile, MUTATION_LOCK }

def _preview(profile: CoachProfile) -> dict[str, any] {
    validation = validate_profile(profile);
    if not validation.valid { raise ValueError(" ".join(validation.errors)); }
    if len(profile.weekdays) > 6 { raise ValueError("Choose 1–6 workout days, leaving room for rest."); }
    account = require_profile();
    current = get_plan_state();
    p = planner_profile(account);
    style = profile.custom_style if profile.goal == "other" else profile.goal;
    p["goal"] = {"fat_loss": "lose", "lean_toned": "active", "muscle": "muscle", "general_strength": "active"}[style];
    p["experience"] = "advanced" if profile.experience == "experienced" else profile.experience;
    p["days"] = len(profile.weekdays);
    p["equipment"] = "gym" if "gym" in profile.equipment else ("dumbbells" if "dumbbells" in profile.equipment else "bodyweight");
    start = max(monday(profile.start_date), (date.fromisoformat(monday()) + timedelta(days=7)).isoformat());
    if start > (date.today() + timedelta(days=90)).isoformat() { raise ValueError("Choose a start within the next 90 days."); }
    settings = {"region": profile.region, "weekdays": sorted(profile.weekdays), "minutes": profile.minutes,
        "goal_note": profile.custom_goal if profile.goal == "other" else profile.goal.replace("_", " "), "constraints": profile.constraints};
    week = make_state(p, start, current["offsets"], current["start_date"] if current["start_date"] < start else "");
    week["routine"] = settings;
    week["completed"] = {};
    week["plan"] = date_plan(routine_week(p, settings, current["offsets"]["strength"], current["offsets"]["cardio"]), start);
    del week["history"];
    return {"week": week, "base": json.dumps(current, sort_keys=True), "warning": validation.warning,
        "note": "Selected from Stride's existing exercise catalog using your confirmed preferences. No photo or injury interpretation is used to prescribe exercises. Bands/mat-only choices use bodyweight exercises. Minutes are a session budget, not a measured duration."};
}

def:priv preview_coach_routine(profile: CoachProfile) -> dict[str, any] {
    return _preview(profile);
}

def:priv save_coach_routine(profile: CoachProfile, expected_state: str) -> dict[str, any] {
    with MUTATION_LOCK {
        p = require_profile();
        state = get_plan_state();
        if json.dumps(state, sort_keys=True) != expected_state { raise ValueError("Your plan changed. Generate a fresh preview before saving."); }
        result = _preview(profile);
        week = result["week"];
        existing = state.get("history", []) + [state] + state.get("upcoming", []);
        if any([w["start_date"] == week["start_date"] for w in existing]) {
            raise ValueError("A week is already saved for those dates. It has been preserved; choose a later start date.");
        }
        upcoming = state.get("upcoming", []) + [week];
        upcoming.sort(key=lambda (w: dict[str, any]) { return w["start_date"]; });
        state["upcoming"] = upcoming;
        p.plan_json = json.dumps(validate_state(state));
        return {"start_date": week["start_date"], "week_id": week["week_id"]};
    }
}
