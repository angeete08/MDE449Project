"""Portable completion and illustrative energy estimates; never calorie targets."""

def exercise_minutes(exercise: dict[str, any]) -> float {
    if exercise.get("duration") { return float(exercise["duration"]); }
    # App planning assumption, not a published per-exercise measurement:
    # 2.5 minutes per ten-rep set, including recovery/setup in the block.
    return float(exercise.get("sets", 2)) * (1.5 + float(exercise.get("reps", 10)) * 0.1);
}

def exercise_met(exercise: dict[str, any]) -> float {
    name = str(exercise.get("name", ""));
    # 2024 Adult Compendium categories: 02101, 17190, 02052,
    # 02024, 02056 and 02054. Categories are matched to our exercise catalog.
    if name == "Gentle mobility" { return 2.3; }
    if exercise.get("duration") { return 3.8; }
    if name in ["Goblet squat", "Dumbbell Romanian deadlift"] { return 5.0; }
    if name in ["Dead bug", "Bird dog", "Glute bridge"] { return 2.8; }
    if name in ["Chair squat", "Incline push-up", "Reverse lunge", "Wall push-up", "Calf raise"] { return 3.0; }
    return 3.5;
}

def exercise_kcal(exercise: dict[str, any]) -> int {
    # Standard MET oxygen-equivalent formula; reference mass 70 kg.
    return max(1, int(exercise_met(exercise) * 3.5 * 70 / 200 * exercise_minutes(exercise) + 0.5));
}

def completed_indices(week: dict[str, any], day: dict[str, any]) -> list[int] {
    if "completed" in week { return week["completed"].get(str(day["index"]), []); }
    # Old day-level ratings implied completion before checkboxes existed.
    return list(range(len(day["exercises"]))) if str(day["index"]) in week.get("feedback", {}) else [];
}

def completed_kcal(week: dict[str, any], day: dict[str, any]) -> int {
    return sum([exercise_kcal(e) for (i, e) in enumerate(day["exercises"]) if i in completed_indices(week, day)]);
}

def day_energy(state: dict[str, any], stamp: str, logs: list[dict[str, any]]) -> dict[str, int] {
    workouts = 0;
    for week in state.get("history", []) + [state] + state.get("upcoming", []) {
        for day in week.get("plan", []) {
            if day["date"] == stamp { workouts += completed_kcal(week, day); }
        }
    }
    logged = sum([int(row.get("calories_burned", 0)) for row in logs if row["date"] == stamp]);
    return {"workouts": workouts, "logged": logged, "total": workouts + logged};
}

def change_completion(week: dict[str, any], index: int, exercise: int, checked: bool, today: str) -> dict[str, any] {
    if isinstance(index, bool) or index not in range(7) { raise ValueError("Choose a valid workout day."); }
    day = week["plan"][index];
    if day["rest"] or day["date"] > today { raise ValueError("Only scheduled workouts through today can be completed."); }
    if isinstance(exercise, bool) or exercise not in range(len(day["exercises"])) or not isinstance(checked, bool) {
        raise ValueError("Choose a valid exercise and completion value.");
    }
    all_done: dict[str, any] = {str(d["index"]): completed_indices(week, d) for d in week["plan"]};
    selected = all_done[str(index)];
    updated = [i for i in selected if i != exercise];
    if checked { updated.append(exercise); }
    all_done[str(index)] = sorted(updated);
    return {**week, "completed": all_done};
}
