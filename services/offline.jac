"""Explicit, account-bound offline snapshots and conditional draft replay."""
import json;
import from planner { validate_state }
import from datetime { date, datetime, timezone }
import from services.stride {
    require_profile, get_plan_state, get_logs, get_health_summary, meal_plan,
    save_log, set_weekly_goal, give_feedback, MUTATION_LOCK
}

def log_value(stamp: str) -> dict[str, any] | None {
    for l in get_logs() {
        if l.date == stamp {
            return {"date": l.date, "steps": l.steps, "calories_burned": l.calories_burned,
                "run_miles": l.run_miles, "active_minutes": l.active_minutes};
        }
    }
    return None;
}

def:priv offline_snapshot() -> dict[str, any] {
    with MUTATION_LOCK {
        p = require_profile();
        return {"version": 1, "owner": jid(root), "name": p.name,
            "saved_at": datetime.now(timezone.utc).isoformat(),
            "goal": p.weekly_minutes_goal, "state": get_plan_state(),
            "logs": [log_value(l.date) for l in get_logs()],
            "health": get_health_summary(), "meals": meal_plan()};
    }
}

# Pure comparison is tested independently of authentication and transport.
def check_change(owner: str, expected_owner: str, current: any, base: any, desired: any) -> str {
    if owner != expected_owner {
        raise ValueError("Sign in to the account that saved these drafts.");
    }
    if current == desired { return "already_applied"; }
    if current != base { return "conflict"; }
    return "apply";
}

def:priv sync_offline_change(owner: str, change: dict[str, any]) -> dict[str, any] {
    with MUTATION_LOCK {
        require_profile();
        if owner != jid(root) {
            raise ValueError("Sign in to the account that saved these drafts.");
        }
        kind = change.get("kind", "");
        desired: any = change.get("value");
        current: any = None;
        if kind == "plan" {
            current = validate_state(get_plan_state());
            desired = validate_state(desired);
            change["base"] = validate_state(change["base"]);
        } elif kind == "log" {
            current = log_value(change["key"]);
        } elif kind == "goal" {
            current = require_profile().weekly_minutes_goal;
        } elif kind == "feedback" {
            state = get_plan_state();
            index = int(change["key"]);
            if index not in range(7) or state["plan"][index]["date"] != change["date"] {
                return {"status": "conflict", "message": "The saved workout belongs to a different week."};
            }
            current = state["feedback"].get(str(index), "");
        } else { raise ValueError("Unsupported offline change."); }
        decision = check_change(owner, jid(root), current, change.get("base"), desired);
        if decision != "apply" {
            return {"status": decision, "current": current};
        }
        if kind == "plan" {
            cleaned = validate_state(desired);
            original = get_plan_state();
            weeks = cleaned["history"] + [cleaned];
            for old in original["history"] + [original] {
                matches = [w for w in weeks if w["week_id"] == old["week_id"]];
                if len(matches) != 1 { raise ValueError("Offline plan must preserve existing weeks."); }
                saved = matches[0];
                for (key, rating) in old["feedback"].items() {
                    if saved["feedback"].get(key) != rating or saved["plan"][int(key)] != old["plan"][int(key)] {
                        raise ValueError("Completed workouts must stay unchanged.");
                    }
                }
            }
            for week in weeks {
                for key in week["feedback"] {
                    if week["plan"][int(key)]["date"] > date.today().isoformat() {
                        raise ValueError("Cannot rate future workouts.");
                    }
                }
            }
            require_profile().plan_json = json.dumps(cleaned);
        } elif kind == "log" {
            if desired["date"] != change["key"] { raise ValueError("Activity date mismatch."); }
            save_log(desired["date"], desired["steps"], desired["calories_burned"],
                desired["run_miles"], desired["active_minutes"], date.today().isoformat());
        } elif kind == "goal" {
            set_weekly_goal(desired);
        } else {
            ratings = {"easy": "too_easy", "right": "just_right", "hard": "too_hard"};
            if desired not in ratings { raise ValueError("Invalid workout rating."); }
            give_feedback(change["key"], str(ratings[desired]), date.today().isoformat());
        }
        return {"status": "applied", "value": desired};
    }
}
