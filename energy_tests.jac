import from planner { make_state }
import from workout_rules { exercise_met, exercise_minutes, exercise_kcal, change_completion, day_energy }

def energy_profile() -> dict[str, any] {
    return {"goal": "muscle", "experience": "beginner", "equipment": "dumbbells", "diet": "none", "days": 3, "calories": 2000};
}

test "activity-specific rates and disclosed block durations replace flat estimates" {
    squat = {"name": "Goblet squat", "sets": 2, "reps": 10};
    press = {"name": "Dumbbell floor press", "sets": 2, "reps": 10};
    core = {"name": "Dead bug", "sets": 2, "reps": 10};
    assert exercise_minutes(squat) == 5.0;
    assert exercise_met(squat) == 5.0 and exercise_met(press) == 3.5 and exercise_met(core) == 2.8;
    assert exercise_kcal(squat) == 31 and exercise_kcal(press) == 21 and exercise_kcal(core) == 17;
    assert exercise_kcal({"name": "Gentle mobility", "duration": 5}) == 14;
    assert exercise_kcal({"name": "Brisk walk or comfortable march", "duration": 20}) == 93;
}

test "daily energy sums matching-date workouts and manual logs without counting other days" {
    week = make_state(energy_profile(), "2026-11-09");
    week = change_completion(week, 0, 0, True, "2026-11-14");
    logs = [{"date": "2026-11-09", "calories_burned": 100}, {"date": "2026-11-14", "calories_burned": 186}];
    monday = day_energy(week, "2026-11-09", logs);
    saturday = day_energy(week, "2026-11-14", logs);
    assert monday == {"workouts": 31, "logged": 100, "total": 131};
    assert saturday == {"workouts": 0, "logged": 186, "total": 186};
    retried = change_completion(week, 0, 0, True, "2026-11-14");
    assert day_energy(retried, "2026-11-09", logs) == monday;
    unchecked = change_completion(retried, 0, 0, False, "2026-11-14");
    assert day_energy(unchecked, "2026-11-09", logs) == {"workouts": 0, "logged": 100, "total": 100};
    # Saving the same activity day replaces its total; totals are recalculated.
    assert day_energy(week, "2026-11-09", [{"date": "2026-11-09", "calories_burned": 150}])["total"] == 181;
}

test "archived and future calendar days use the same energy calculation" {
    archived = make_state(energy_profile(), "2026-11-09");
    archived = change_completion(archived, 0, 0, True, "2026-11-14");
    del archived["history"];
    current = make_state(energy_profile(), "2026-11-16");
    current["history"] = [archived];
    assert day_energy(current, "2026-11-09", [{"date": "2026-11-09", "calories_burned": 80}])["total"] == 111;
    assert day_energy(current, "2026-11-16", [])["total"] == 0;
    assert day_energy(current, "2026-11-10", [{"date": "2026-11-10", "calories_burned": 50}])["total"] == 50;
}
