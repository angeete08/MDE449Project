"""Server-side planning rules. JSON dictionaries are the browser boundary."""
import copy;
import from datetime { date, timedelta }
import from uuid { uuid4, UUID }

def validate_profile(p: dict[str, any]) -> dict[str, any] {
    choices = {"goal": ["active", "muscle", "lose"], "experience": ["beginner", "intermediate", "advanced"], "equipment": ["bodyweight", "dumbbells", "gym"], "diet": ["none", "vegetarian", "keto", "protein"]};
    for (key, allowed) in choices.items() {
        if p.get(key) not in allowed { raise ValueError("Please choose a valid " + key + "."); }
    }
    for (key, low, high) in [("days", 1, 6), ("calories", 1, 10000)] {
        value = p.get(key);
        if not isinstance(value, int) or isinstance(value, bool) or value < low or value > high {
            raise ValueError("Enter a whole-number " + key + " value between " + str(low) + " and " + str(high) + ".");
        }
    }
    return {key: p[key] for key in ["goal", "experience", "equipment", "diet", "days", "calories"]};
}

def generate_week(p: dict[str, any], strength_offset: int = 0, cardio_offset: int = 0) -> list[dict[str, any]] {
    validate_profile(p);
    schedule = {1: [0], 2: [0, 3], 3: [0, 2, 4], 4: [0, 1, 3, 5], 5: [0, 1, 2, 4, 5], 6: [0, 1, 2, 3, 4, 5]};
    slots = schedule[p["days"]];
    lifts = {
        "bodyweight": [["Chair squat", "Incline push-up", "Glute bridge", "Bird dog"], ["Reverse lunge", "Wall push-up", "Calf raise", "Dead bug"]],
        "dumbbells": [["Goblet squat", "Dumbbell floor press", "Dumbbell row", "Dead bug"], ["Dumbbell reverse lunge", "Dumbbell shoulder press", "Dumbbell Romanian deadlift", "Bird dog"]],
        "gym": [["Leg press", "Chest press machine", "Seated cable row", "Dead bug"], ["Leg curl machine", "Lat pulldown", "Cable chest press", "Bird dog"]]
    };
    base = {"beginner": 2, "intermediate": 3, "advanced": 4}[p["experience"]];
    week: list[dict[str, any]] = [];
    for (i, day) in enumerate(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]) {
        if i not in slots {
            week.append({"day": day, "index": i, "rest": True, "title": "Rest & recharge", "exercises": [], "note": "Take the day off. Optional gentle stretching if it feels good."});
            continue;
        }
        n = slots.index(i);
        cardio = (n % 2 == 1) if p["goal"] == "lose" else ((n % 3 == 1) if p["goal"] == "active" else (n % 4 == 3));
        reps = max(6, min(16, 10 + strength_offset));
        duration = max(10, min(40, 20 + cardio_offset * 2));
        exercises: list[dict[str, any]] = [];
        if cardio {
            exercises = [{"name": "Brisk walk or comfortable march", "duration": duration}, {"name": "Gentle mobility", "duration": 5}];
        } else {
            exercises = [{"name": name, "sets": base, "reps": reps} for name in lifts[p["equipment"]][n % 2]];
        }
        title = "Cardio & mobility" if cardio else ("Strength B" if n % 2 else "Strength A");
        note = "Use a pace that feels comfortable." if cardio else "Move slowly and choose a comfortable resistance.";
        week.append({"day": day, "index": i, "rest": False, "title": title, "exercises": exercises, "note": note});
    }
    return week;
}

def meal_ideas(diet: str) -> list[dict[str, any]] {
    menus = {
        "vegetarian": [("Greek yogurt oat bowl", 410, "Yogurt, oats, berries and chia; one bowl."), ("Chickpea quinoa salad", 520, "Chickpeas, quinoa, vegetables and olive oil; one bowl."), ("Tofu vegetable stir-fry", 560, "Tofu, brown rice and vegetables; one plate.")],
        "keto": [("Spinach and egg skillet", 390, "Two eggs, spinach, avocado and olive oil; one plate."), ("Chicken avocado salad", 510, "Chicken, greens, avocado and olive oil; one bowl."), ("Salmon with broccoli", 580, "Salmon, broccoli and butter; one plate.")],
        "protein": [("Cottage cheese berry bowl", 400, "Cottage cheese, berries, oats and nuts; one bowl."), ("Chicken rice bowl", 580, "Chicken breast, rice, beans and vegetables; one bowl."), ("Turkey lentil chili", 540, "Turkey, lentils, tomatoes and vegetables; one bowl.")],
        "none": [("Peanut butter overnight oats", 430, "Oats, milk, banana and peanut butter; one jar."), ("Chicken grain bowl", 570, "Chicken, rice, vegetables and dressing; one bowl."), ("Bean and vegetable tacos", 510, "Beans, vegetables, cheese and three small tortillas.")]
    };
    return [{"name": name, "calories": calories, "detail": detail} for (name, calories, detail) in menus[diet]];
}

def monday(value: str = "") -> str {
    day = date.fromisoformat(value) if value else date.today();
    return (day - timedelta(days=day.weekday())).isoformat();
}

def offsets(value: dict[str, any]) -> dict[str, any] {
    result: dict[str, any] = {};
    for key in ["strength", "cardio"] {
        number = value.get(key);
        if not isinstance(number, int) or isinstance(number, bool) or abs(number) > 4 { raise ValueError("Invalid saved difficulty."); }
        result[key] = number;
    }
    return result;
}

def date_plan(plan: list[dict[str, any]], start: str) -> list[dict[str, any]] {
    for (i, day) in enumerate(plan) { day["date"] = (date.fromisoformat(start) + timedelta(days=i)).isoformat(); }
    return plan;
}

def memory_note(week: dict[str, any]) -> str {
    start = week["starting_offsets"];
    source = week["source_week"];
    prefix = "Starting baseline. ";
    if source { prefix = "Based on your saved difficulty at the end of the week of " + source + ". "; }
    if week["legacy_dates"] { prefix = "Imported older plan: dates were assigned during migration, not recorded originally. Legacy shared difficulty was retained for both training types. "; }
    return prefix + "Strength starts at " + str(10 + start["strength"]) + " reps per set; cardio starts at " + str(20 + start["cardio"] * 2) + " minutes. Previous ratings are not counted again.";
}

def make_state(p: dict[str, any], start_date: str = "", inherited: dict[str, any] | None = None, source_week: str = "") -> dict[str, any] {
    clean = validate_profile(p);
    start = monday(start_date);
    level = offsets(inherited) if inherited is not None else {"strength": 0, "cardio": 0};
    return {"schema_version": 2, "week_id": str(uuid4()), "start_date": start, "end_date": (date.fromisoformat(start) + timedelta(days=6)).isoformat(), "source_week": source_week, "legacy_dates": False, "profile": clean, "offsets": level, "starting_offsets": copy.deepcopy(level), "feedback": {}, "plan": date_plan(generate_week(clean, level["strength"], level["cardio"]), start), "meals": meal_ideas(clean["diet"]), "history": []};
}

# A snapshot has no nested history. Old workout amounts are retained exactly.
def validate_week(state: dict[str, any], migration_date: str = "") -> dict[str, any] {
    profile = validate_profile(state.get("profile", {}));
    legacy = "schema_version" not in state;
    level: dict[str, any] = {};
    if legacy {
        old_offset = state.get("offset", 0);
        level = offsets({"strength": old_offset, "cardio": old_offset});
    } else {
        if state.get("schema_version") != 2 { raise ValueError("Unsupported saved data version."); }
        level = offsets(state.get("offsets", {}));
    }
    clean = make_state(profile, migration_date, level);
    if legacy { clean["legacy_dates"] = True; }
    else {
        start = state.get("start_date", "");
        if not isinstance(start, str) or not start or monday(start) != start { raise ValueError("Invalid week start date."); }
        week_id = state.get("week_id", "");
        if not isinstance(week_id, str) or str(UUID(week_id)) != week_id { raise ValueError("Invalid week ID."); }
        source = state.get("source_week", "");
        if source and (not isinstance(source, str) or monday(source) != source or date.fromisoformat(source) + timedelta(days=7) != date.fromisoformat(start)) { raise ValueError("Invalid source week."); }
        if not isinstance(state.get("legacy_dates"), bool) { raise ValueError("Invalid migration flag."); }
        clean = make_state(profile, start, level, source);
        clean["week_id"] = week_id;
        clean["starting_offsets"] = offsets(state.get("starting_offsets", {}));
        clean["legacy_dates"] = state["legacy_dates"];
    }
    feedback = state.get("feedback", {});
    plan = state.get("plan", []);
    if not isinstance(feedback, dict) or not isinstance(plan, list) or len(plan) != 7 { raise ValueError("Invalid saved week."); }
    for (i, day) in enumerate(clean["plan"]) {
        old = plan[i];
        if not isinstance(old, dict) or old.get("day") != day["day"] or old.get("rest") != day["rest"] or old.get("title") != day["title"] { raise ValueError("Invalid saved workout."); }
        exercises = old.get("exercises", []);
        if not isinstance(exercises, list) or len(exercises) != len(day["exercises"]) { raise ValueError("Invalid saved exercises."); }
        for (j, exercise) in enumerate(day["exercises"]) {
            stored = exercises[j];
            if not isinstance(stored, dict) or stored.get("name") != exercise["name"] { raise ValueError("Invalid saved exercise."); }
            metric = "duration" if "duration" in exercise else "reps";
            value = stored.get(metric);
            low = (5 if j == 1 else 10) if metric == "duration" else 6;
            high = (5 if j == 1 else 40) if metric == "duration" else 16;
            if not isinstance(value, int) or isinstance(value, bool) or not low <= value <= high { raise ValueError("Invalid saved exercise amount."); }
            if "sets" in exercise and stored.get("sets") != exercise["sets"] { raise ValueError("Invalid saved sets."); }
            exercise[metric] = value;
        }
    }
    for (key, rating) in feedback.items() {
        if key not in [str(i) for i in range(7)] or rating not in ["easy", "right", "hard"] or clean["plan"][int(key)]["rest"] { raise ValueError("Invalid saved feedback."); }
    }
    clean["feedback"] = copy.deepcopy(feedback);
    clean["memory_note"] = memory_note(clean);
    del clean["history"];
    return clean;
}

def validate_state(state: dict[str, any], migration_date: str = "") -> dict[str, any] {
    clean = validate_week(state, migration_date);
    history = state.get("history", []);
    if not isinstance(history, list) { raise ValueError("Invalid saved history."); }
    clean["history"] = [];
    seen: list[str] = [];
    previous = "";
    for item in history {
        if not isinstance(item, dict) or "history" in item { raise ValueError("Invalid history snapshot."); }
        week = validate_week(item);
        if week["week_id"] in seen or week["start_date"] >= clean["start_date"] or (previous and week["start_date"] <= previous) { raise ValueError("Duplicate or unordered history."); }
        seen.append(week["week_id"]);
        previous = week["start_date"];
        clean["history"].append(week);
    }
    if clean["week_id"] in seen { raise ValueError("Duplicate current week."); }
    return clean;
}

def update_feedback(state: dict[str, any], index: int, rating: str) -> dict[str, any] {
    clean = validate_state(state);
    if not isinstance(index, int) or isinstance(index, bool) or not 0 <= index <= 6 or rating not in ["easy", "right", "hard"] { raise ValueError("Invalid workout feedback."); }
    key = str(index);
    if clean["plan"][index]["rest"] { raise ValueError("Choose a workout day."); }
    if key in clean["feedback"] { raise ValueError("This workout has already been logged."); }
    kind = "cardio" if clean["plan"][index]["title"] == "Cardio & mobility" else "strength";
    delta = 1 if rating == "easy" else (-1 if rating == "hard" else 0);
    before = clean["offsets"][kind];
    clean["offsets"][kind] = max(-4, min(4, before + delta));
    if before != clean["offsets"][kind] {
        updated = date_plan(generate_week(clean["profile"], clean["offsets"]["strength"], clean["offsets"]["cardio"]), clean["start_date"]);
        for i in range(index + 1, 7) {
            same_kind = (updated[i]["title"] == "Cardio & mobility") == (kind == "cardio");
            if not updated[i]["rest"] and same_kind and str(i) not in clean["feedback"] { clean["plan"][i] = updated[i]; }
        }
    }
    clean["feedback"][key] = rating;
    return clean;
}

def:pub create_plan(profile: dict[str, any], previous: dict[str, any] | None = None, start_date: str = "") -> dict[str, any] {
    try {
        state = make_state(profile, start_date);
        if previous {
            old = validate_state(previous, start_date);
            next_start = (date.fromisoformat(old["start_date"]) + timedelta(days=7)).isoformat();
            state = make_state(profile, next_start, old["offsets"], old["start_date"]);
            history = old.pop("history");
            history.append(old);
            state["history"] = history;
        }
        state["memory_note"] = memory_note(state);
        return {"ok": True, "state": state, "message": "New week ready. Previous workouts are archived and difficulty is carried forward." if previous else "Your first week is ready."};
    } except (ValueError, TypeError, KeyError, IndexError, AttributeError, OverflowError) as error { return {"ok": False, "message": str(error)}; }
}

def:pub submit_feedback(state: dict[str, any], index: int, rating: str) -> dict[str, any] {
    try {
        updated = update_feedback(state, index, rating);
        return {"ok": True, "state": updated, "message": "Workout logged. Only later unlogged workouts of the same type may change. Your saved difficulty will carry into the next week."};
    } except (ValueError, TypeError, KeyError, IndexError, AttributeError, OverflowError) as error { return {"ok": False, "message": str(error)}; }
}

def:pub restore_plan(state: dict[str, any], migration_date: str = "") -> dict[str, any] {
    try { return {"ok": True, "state": validate_state(state, migration_date), "message": "Your current week and workout history are restored."}; }
    except (ValueError, TypeError, KeyError, IndexError, AttributeError, OverflowError) { return {"ok": False, "message": "Saved data could not be restored. It has not been overwritten. Retry loading, or explicitly clear saved data to start over."}; }
}
