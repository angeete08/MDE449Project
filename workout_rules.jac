"""Portable completion and illustrative energy estimates; never calorie targets."""

def exercise_kcal(exercise: dict[str, any]) -> int {
    # 2024 Adult Compendium: resistance 3.5 MET, moderate walking 3.8,
    # mild stretching 2.3. Reference mass 70 kg; not a personal measurement.
    duration = float(exercise.get("duration", 0));
    met = 2.3 if exercise.get("name") == "Gentle mobility" else 3.8;
    if not duration {
        sets = float(exercise.get("sets", 2));
        duration = sets * float(exercise.get("reps", 10)) * 3 / 60 + max(0.0, sets - 1.0) * 0.75;
        met = 3.5;
    }
    return max(1, int(met * 70 * duration / 60 + 0.5));
}

def completed_indices(week: dict[str, any], day: dict[str, any]) -> list[int] {
    if "completed" in week { return week["completed"].get(str(day["index"]), []); }
    # Old day-level ratings implied completion before checkboxes existed.
    return list(range(len(day["exercises"]))) if str(day["index"]) in week.get("feedback", {}) else [];
}

def completed_kcal(week: dict[str, any], day: dict[str, any]) -> int {
    return sum([exercise_kcal(e) for (i, e) in enumerate(day["exercises"]) if i in completed_indices(week, day)]);
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
