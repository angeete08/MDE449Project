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
    assert state["offset"] == 4;
    rejected = False;
    try { update_feedback(state, 0, "hard"); }
    except ValueError { rejected = True; }
    assert rejected;
    for rating in ["easy", "right", "hard"] {
        s = update_feedback(make_state(profile()), 0, rating);
        assert s["plan"][2]["exercises"][0]["reps"] == {"easy": 11, "right": 10, "hard": 9}[rating];
    }
    s = update_feedback(make_state(profile(goal="active")), 0, "hard");
    assert s["plan"][2]["exercises"][0]["duration"] == 18;
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
