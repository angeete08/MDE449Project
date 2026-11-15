"""Portable, constrained exercise selection from Stride's existing catalog."""
import from planning_rules { generate_week }

def routine_week(profile: dict[str, any], routine: dict[str, any], strength: int = 0, cardio: int = 0) -> list[dict[str, any]] {
    days = routine.get("weekdays", []);
    region = routine.get("region", "full_body");
    minutes = routine.get("minutes", 30);
    focus = {
        "shoulders": ["shoulder", "push-up"], "arms": ["press", "push-up", "row"],
        "chest": ["press", "push-up"], "back": ["row", "pulldown", "Bird"],
        "core": ["Dead bug", "Bird dog"], "glutes": ["squat", "bridge", "deadlift", "lunge"],
        "legs": ["squat", "lunge", "Leg", "Calf"], "full_body": [], "unknown": []
    };
    if region not in focus or not isinstance(days, list) or not 1 <= len(days) <= 6 {
        raise ValueError("Choose a focus and 1–6 workout days.");
    }
    if any([not isinstance(d, int) or isinstance(d, bool) or d not in range(7) for d in days]) or len(set(days)) != len(days) {
        raise ValueError("Choose unique weekdays.");
    }
    if not isinstance(minutes, int) or isinstance(minutes, bool) or not 10 <= minutes <= 120 {
        raise ValueError("Choose 10–120 minutes.");
    }
    if profile["days"] != len(days) { raise ValueError("Workout count does not match weekdays."); }
    source = [d for d in generate_week(profile, strength, cardio) if not d["rest"]];
    pool: list[dict[str, any]] = [];
    for d in generate_week({**profile, "goal": "muscle", "days": 2}, strength, cardio) {
        for e in d["exercises"] {
            if not any([x["name"] == e["name"] for x in pool]) { pool.append(e); }
        }
    }
    result: list[dict[str, any]] = [];
    ordered = sorted(days);
    for (i, name) in enumerate(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]) {
        if i not in ordered {
            result.append({"day": name, "index": i, "rest": True, "title": "Rest & recharge", "exercises": [], "note": "Optional gentle movement or rest."});
            continue;
        }
        day = source[ordered.index(i)];
        exercises: list[dict[str, any]] = [];
        if day["title"] == "Cardio & mobility" {
            exercises = [{"name": "Brisk walk or comfortable march", "duration": max(5, minutes - 5 + cardio * 2)}, {"name": "Gentle mobility", "duration": 5}];
        } else {
            preferred = [e for e in pool if any([word.lower() in e["name"].lower() for word in focus[region]])];
            selected: list[dict[str, any]] = [];
            for e in preferred[:2] + day["exercises"] + pool {
                if not any([x["name"] == e["name"] for x in selected]) { selected.append(e); }
            }
            exercises = [{**e, "sets": max(1, min(4, minutes // 10))} for e in selected[:4]];
        }
        result.append({**day, "day": name, "index": i, "exercises": exercises});
    }
    return result;
}
