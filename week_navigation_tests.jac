import copy;
import from planner { make_state, create_plan, current_week_state, preview_week_state, update_feedback, validate_state }

def navigation_profile() -> dict[str, any] {
    return {"goal": "muscle", "days": 3, "equipment": "bodyweight", "diet": "vegetarian", "experience": "beginner", "calories": 2000};
}

test "opening the same week preserves every saved workout and meal" {
    p = navigation_profile();
    state = update_feedback(make_state(p, "2026-10-19"), 0, "hard");
    before = copy.deepcopy(state);
    changed_profile = navigation_profile();
    changed_profile["days"] = 5;
    current = current_week_state(changed_profile, state, "2026-10-25");
    assert current == before;
    assert state == before;
    assert current_week_state(p, current, "2026-10-25") == current;
}

test "catch up directly to this week without creating missing weeks" {
    p = navigation_profile();
    old = update_feedback(make_state(p, "2026-10-05"), 0, "hard");
    before = copy.deepcopy(old);
    current = current_week_state(p, old, "2026-11-05");
    assert current["start_date"] == "2026-11-02";
    assert current["source_week"] == "2026-10-05";
    assert current["offsets"] == old["offsets"];
    assert current["plan"][0]["exercises"][0]["reps"] == 9;
    assert len(current["history"]) == 1;
    assert current["history"][0]["plan"] == old["plan"];
    assert old == before;
    assert validate_state(current) == current;
}

test "recover an archived current week and retain future weeks exactly" {
    p = navigation_profile();
    first = update_feedback(make_state(p, "2026-10-19"), 0, "hard");
    second = create_plan(p, first)["state"];
    third = create_plan(p, second)["state"];
    before = copy.deepcopy(third);
    recovered = current_week_state(p, third, "2026-10-21");
    assert recovered["week_id"] == first["week_id"];
    assert recovered["plan"] == first["plan"];
    assert recovered["feedback"] == first["feedback"];
    assert recovered["meals"] == first["meals"];
    assert len(recovered["upcoming"]) == 2;
    assert recovered["upcoming"][1]["plan"] == third["plan"];
    assert third == before;
    assert validate_state(recovered) == recovered;
    recovered = update_feedback(recovered, 2, "easy");
    assert len(recovered["upcoming"]) == 2;
    later = current_week_state(p, recovered, "2026-10-28");
    assert later["week_id"] == second["week_id"];
    assert later["plan"] == second["plan"];
    assert later["history"][0]["feedback"] == recovered["feedback"];
    assert len(later["upcoming"]) == 1;
    assert validate_state(later) == later;
}

test "generate missing current week without learning from future feedback" {
    p = navigation_profile();
    future = update_feedback(make_state(p, "2026-11-09"), 0, "hard");
    current = current_week_state(p, future, "2026-11-05");
    assert current["start_date"] == "2026-11-02";
    assert current["offsets"]["strength"] == 0;
    assert current["history"] == [];
    assert current["upcoming"][0]["feedback"] == future["feedback"];
    assert validate_state(current) == current;
}

test "preview is read only and follows the calendar rather than an old plan" {
    p = navigation_profile();
    old = update_feedback(make_state(p, "2026-10-05"), 0, "hard");
    before = copy.deepcopy(old);
    for i in range(3) {
        preview = preview_week_state(p, old, "2026-11-05");
        assert preview["start_date"] == "2026-11-09";
        assert preview["offsets"] == old["offsets"];
        assert old == before;
    }
}

test "preview reuses a preserved future plan without changing ratings" {
    p = navigation_profile();
    first = make_state(p, "2026-11-02");
    future = update_feedback(create_plan(p, first)["state"], 0, "hard");
    current = current_week_state(p, future, "2026-11-05");
    before = copy.deepcopy(current);
    preview = preview_week_state(p, current, "2026-11-05");
    assert preview["week_id"] == future["week_id"];
    assert preview["plan"] == future["plan"];
    assert preview["feedback"] == future["feedback"];
    assert current == before;
}

test "calendar transitions cross year boundaries and invalid dates fail" {
    p = navigation_profile();
    old = make_state(p, "2026-12-28");
    assert current_week_state(p, old, "2027-01-03")["start_date"] == "2026-12-28";
    current = current_week_state(p, old, "2027-01-04");
    assert current["start_date"] == "2027-01-04";
    assert preview_week_state(p, current, "2027-01-04")["start_date"] == "2027-01-11";
    rejected = False;
    try { current_week_state(p, old, "2026-02-30"); }
    except ValueError { rejected = True; }
    assert rejected;
}

test "duplicate and invalid retained future weeks are rejected" {
    p = navigation_profile();
    future = create_plan(p, make_state(p, "2026-11-02"))["state"];
    current = current_week_state(p, future, "2026-11-05");
    for duplicate in [True, False] {
        bad = copy.deepcopy(current);
        if duplicate {
            bad["upcoming"].append(copy.deepcopy(bad["upcoming"][0]));
        } else {
            bad["upcoming"][0]["plan"][0]["exercises"][0]["reps"] = 999;
        }
        rejected = False;
        try { current_week_state(p, bad, "2026-11-05"); }
        except ValueError { rejected = True; }
        assert rejected;
    }
}

test "sequential navigation restores retained weeks and their feedback" {
    p = navigation_profile();
    first = make_state(p, "2026-11-02");
    second = update_feedback(create_plan(p, first)["state"], 0, "hard");
    third = create_plan(p, second)["state"];
    restored = current_week_state(p, third, "2026-11-02");
    advanced = create_plan(p, restored)["state"];
    assert advanced["week_id"] == second["week_id"];
    assert advanced["feedback"] == second["feedback"];
    assert advanced["upcoming"][0]["week_id"] == third["week_id"];
    assert validate_state(advanced) == advanced;
}
