import from services.stride {
    Profile,
    DailyLog,
    planner_profile,
    plan_days,
    activity_summary,
    validate_log,
    movement_break,
    calendar_date
}
import from planner { make_state, update_feedback }

test "weekly activity respects Monday Sunday and future boundaries" {
    logs = [
        DailyLog(date="2026-10-18", active_minutes=900),
        DailyLog(date="2026-10-19", active_minutes=30),
        DailyLog(date="2026-10-24", active_minutes=40),
        DailyLog(date="2026-10-25", active_minutes=20, steps=4000),
        DailyLog(date="2026-10-26", active_minutes=800)
    ];
    sunday = activity_summary(logs, "2026-10-25", 150);
    assert sunday["weekly_minutes"] == 90;
    assert sunday["remaining"] == 60;
    assert sunday["steps"] == 4000;
    assert sunday["streak"] == 2;
    monday = activity_summary(logs, "2026-10-26", 150);
    assert monday["weekly_minutes"] == 800;
    assert monday["percent"] == 100;
    assert monday["remaining"] == 0;
}

test "missing log and zero log are distinct and streak crosses months" {
    empty = activity_summary([], "2026-11-01", 30);
    assert not empty["logged_today"];
    zeros = activity_summary([DailyLog(date="2026-11-01")], "2026-11-01", 30);
    assert zeros["logged_today"];
    assert zeros["streak"] == 0;
    logs = [
        DailyLog(date="2026-10-30", steps=10),
        DailyLog(date="2026-10-31", active_minutes=3)
    ];
    assert activity_summary(logs, "2026-11-01", 30)["streak"] == 2;
    assert activity_summary(logs, "2026-11-02", 30)["streak"] == 0;
}

test "invalid activity totals and dates rejected" {
    validate_log("2026-10-25", 0, 0, 0.0, 0, "2026-10-25");
    for bad_date in ["2026-02-30", "2026-10-26", "not-a-date"] {
        with testraises(ValueError) {
            validate_log(bad_date, 0, 0, 0.0, 0, "2026-10-25");
        }
    }
    with testraises(ValueError) {
        validate_log("2026-10-25", -1, 0, 0.0, 0, "2026-10-25");
    }
    with testraises(ValueError) {
        validate_log("2026-10-25", 0, 0, float("nan"), 0, "2026-10-25");
    }
    with testraises(ValueError) {
        validate_log("2026-10-25", 0, 0, 0.0, 1441, "2026-10-25");
    }
}

test "movement breaks depend on explicit input" {
    assert not movement_break(59)["suggested"];
    assert movement_break(60)["suggested"];
    assert len(movement_break(120)["steps"]) == 3;
    with testraises(ValueError) {
        movement_break(-1);
    }
    with testraises(ValueError) {
        movement_break(1441);
    }
}

test "dashboard adapter preserves order exercise amounts and logged workouts" {
    p = Profile(
        name="Adapter test",
        goal="gain_muscle",
        level="beginner",
        days_per_week=3,
        diet="high_protein",
        calorie_target=2100
    );
    clean = planner_profile(p);
    assert clean["goal"] == "muscle" and clean["diet"] == "protein";
    assert clean["equipment"] == "bodyweight" and clean["calories"] == 2100;
    original = make_state(clean, "2026-10-19");
    changed = update_feedback(original, 0, "hard");
    days = plan_days(changed);
    assert [d.order for d in days] == list(range(7));
    assert days[0].date == "2026-10-19" and days[6].date == "2026-10-25";
    assert days[0].feedback == "hard";
    assert days[0].exercises == original["plan"][0]["exercises"];
    assert days[2].exercises[0]["reps"] == 9;
}
