import copy;
import from planner { make_state, generate_week, create_plan, update_feedback, restore_plan, meal_ideas }

def profile(goal: str = "muscle", days: int = 3, equipment: str = "bodyweight", diet: str = "vegetarian", experience: str = "beginner") -> dict[str, any] {
    return {"goal": goal, "days": days, "equipment": equipment, "diet": diet, "experience": experience, "calories": 2000};
}

test "all profile combinations" {
    count = 0;
    for goal in ["active", "lose", "muscle"] {
        for experience in ["beginner", "intermediate", "advanced"] {
            for days in range(1, 7) {
                for equipment in ["bodyweight", "dumbbells", "gym"] {
                    for diet in ["none", "vegetarian", "keto", "protein"] {
                        state = make_state(profile(goal, days, equipment, diet, experience));
                        assert len(state["plan"]) == 7;
                        assert len([day for day in state["plan"] if not day["rest"]]) == days;
                        assert state["plan"][6]["rest"];
                        assert len(state["meals"]) == 3;
                        for day in state["plan"] {
                            for exercise in day["exercises"] {
                                if equipment == "bodyweight" {
                                    assert "Dumbbell" not in exercise["name"];
                                    assert "machine" not in exercise["name"];
                                    assert "cable" not in exercise["name"];
                                }
                            }
                        }
                        count += 1;
                    }
                }
            }
        }
    }
    assert count == 648;
}

test "feedback preserves past and logged workouts" {
    state = make_state(profile());
    previous = copy.deepcopy(state);
    state = update_feedback(state, 2, "hard");
    assert state["plan"][0] == previous["plan"][0];
    assert state["plan"][2] == previous["plan"][2];
    assert state["plan"][4]["exercises"][0]["reps"] == 9;
    assert state["feedback"]["2"] == "hard";
    state = update_feedback(state, 0, "easy");
    assert state["plan"][2] == previous["plan"][2];
    assert state["plan"][4]["exercises"][0]["reps"] == 10;
}

test "invalid inputs are rejected" {
    for (key, value) in [("days", 0), ("days", 7), ("days", 2.5), ("calories", -1), ("calories", True), ("diet", "invalid")] {
        p = profile(); p[key] = value;
        assert not create_plan(p)["ok"];
    }
    assert not restore_plan({})["ok"];
    state = make_state(profile());
    state["plan"][0]["exercises"][0]["name"] = "Untrusted saved text";
    assert not restore_plan(state)["ok"];
}

test "feedback bounds and duplicate logs" {
    state = make_state(profile(days=6));
    for i in range(5) { state = update_feedback(state, i, "easy"); }
    assert state["offsets"]["strength"] == 4;
    rejected = False;
    try { update_feedback(state, 0, "hard"); }
    except ValueError { rejected = True; }
    assert rejected;
    for rating in ["easy", "right", "hard"] {
        s = update_feedback(make_state(profile()), 0, rating);
        assert s["plan"][2]["exercises"][0]["reps"] == {"easy": 11, "right": 10, "hard": 9}[rating];
    }
    s = update_feedback(make_state(profile(goal="active")), 0, "hard");
    assert s["plan"][2]["exercises"][0]["duration"] == 20;
}

test "saved plan round trip" {
    state = update_feedback(make_state(profile()), 0, "hard");
    restored = restore_plan(state);
    assert restored["ok"];
    assert restored["state"] == state;
}

test "meal ideas adapt to calories and randomize" {
    lighter = meal_ideas("protein", 1200);
    higher = meal_ideas("protein", 3000);
    assert len(lighter) == 3;
    assert len(higher) == 3;
    assert max([meal["calories"] for meal in lighter]) <= 470;
    assert min([meal["calories"] for meal in higher]) >= 480;
    first = meal_ideas("vegetarian", 2000);
    second = meal_ideas("vegetarian", 2000);
    assert first != second;
}

test "new week archives exact history and inherits without replay" {
    first = create_plan(profile(), start_date="2026-10-07")["state"];
    assert first["start_date"] == "2026-10-05";
    first = update_feedback(first, 0, "hard");
    first = update_feedback(first, 2, "hard");
    before = copy.deepcopy(first);
    second = create_plan(profile(), first)["state"];
    assert first == before;
    assert second["start_date"] == "2026-10-12";
    assert second["plan"][6]["date"] == "2026-10-18";
    assert second["week_id"] != first["week_id"];
    assert second["offsets"] == {"strength": -2, "cardio": 0};
    assert second["plan"][0]["exercises"][0]["reps"] == 8;
    assert second["feedback"] == {};
    assert second["history"][0]["plan"] == first["plan"];
    assert second["history"][0]["feedback"] == first["feedback"];
    assert "history" not in second["history"][0];
    assert "8 reps" in second["memory_note"];
    third = create_plan(profile(), second)["state"];
    assert third["offsets"] == second["offsets"];
    assert len(third["history"]) == 2;
    assert restore_plan(third)["state"] == third;
}

test "strength and cardio feedback are independent" {
    state = create_plan(profile(goal="active", days=6), start_date="2026-10-05")["state"];
    state = update_feedback(state, 1, "hard");
    assert state["offsets"] == {"strength": 0, "cardio": -1};
    assert state["plan"][2]["exercises"][0]["reps"] == 10;
    assert state["plan"][4]["exercises"][0]["duration"] == 18;
    state = update_feedback(state, 2, "easy");
    assert state["offsets"] == {"strength": 1, "cardio": -1};
    assert state["plan"][4]["exercises"][0]["duration"] == 18;
    next_state = create_plan(profile(goal="active", days=6), state)["state"];
    assert next_state["plan"][0]["exercises"][0]["reps"] == 11;
    assert next_state["plan"][1]["exercises"][0]["duration"] == 18;
    assert next_state["plan"][1]["exercises"][1]["duration"] == 5;
}

test "just right never changes workouts even with out of order logs" {
    state = create_plan(profile(days=6))["state"];
    state = update_feedback(state, 4, "hard");
    old_plan = copy.deepcopy(state["plan"]);
    state = update_feedback(state, 0, "right");
    assert state["plan"] == old_plan;
}

test "last workout feedback carries into next week and archive is immutable" {
    state = create_plan(profile(days=1), start_date="2026-12-28")["state"];
    state = update_feedback(state, 0, "hard");
    assert state["plan"][0]["exercises"][0]["reps"] == 10;
    next_state = create_plan(profile(days=1), state)["state"];
    assert next_state["start_date"] == "2027-01-04";
    assert next_state["plan"][0]["exercises"][0]["reps"] == 9;
    archive = copy.deepcopy(next_state["history"]);
    next_state = update_feedback(next_state, 0, "easy");
    assert next_state["history"] == archive;
}

test "legacy browser data migrates without losing logged workouts" {
    p = profile(goal="active");
    legacy = {"profile": p, "offset": -1, "feedback": {"0": "hard"}, "plan": generate_week(p, -1, -1), "meals": []};
    legacy["plan"][0]["exercises"][0]["reps"] = 10;
    result = restore_plan(legacy, "2026-10-07");
    assert result["ok"];
    state = result["state"];
    assert state["legacy_dates"];
    assert state["start_date"] == "2026-10-05";
    assert state["feedback"] == legacy["feedback"];
    assert state["plan"][0]["exercises"][0]["reps"] == 10;
    assert state["offsets"] == {"strength": -1, "cardio": -1};
    assert restore_plan(state)["state"] == state;
}

test "malformed history and dates do not silently overwrite data" {
    first = create_plan(profile(), start_date="2026-10-05")["state"];
    second = create_plan(profile(), first)["state"];
    bad = copy.deepcopy(second);
    bad["history"].append(copy.deepcopy(bad["history"][0]));
    assert not restore_plan(bad)["ok"];
    assert not create_plan(profile(), bad)["ok"];
    bad = copy.deepcopy(second);
    bad["offsets"]["strength"] = True;
    assert not restore_plan(bad)["ok"];
    assert not create_plan(profile(), start_date="invalid")["ok"];
    bad = copy.deepcopy(second);
    bad["history"][0]["plan"][0]["exercises"][0]["reps"] = 999;
    assert not restore_plan(bad)["ok"];
    assert second["history"][0]["plan"] == first["plan"];
}
