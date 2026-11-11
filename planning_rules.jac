"""Portable planning rules shared by the server and offline browser."""
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
    clean = {key: p[key] for key in ["goal", "experience", "equipment", "diet", "days", "calories"]};
    for (key, low, high) in [("avg_daily_steps", 0, 100000), ("avg_heart_rate", 20, 250), ("avg_sleep_hours", 0, 24), ("avg_workouts_per_week", 0, 50)] {
        value = p.get(key);
        if value is not None and (not isinstance(value, (int, float)) or isinstance(value, bool) or value < low or value > high or value != value) {
            raise ValueError("Enter a valid value for " + key + ".");
        }
        clean[key] = value;
    }
    return clean;
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

def meal_catalog(diet: str) -> list[dict[str, any]] {
    menus = {
        "vegetarian": [
            ("Greek yogurt oat bowl", 410, "Yogurt, oats, berries and chia; one bowl."),
            ("Chickpea quinoa salad", 520, "Chickpeas, quinoa, vegetables and olive oil; one bowl."),
            ("Tofu vegetable stir-fry", 560, "Tofu, brown rice and vegetables; one plate."),
            ("Lentil grain bowl", 480, "Lentils, farro, greens and roasted vegetables; one bowl."),
            ("Black bean sweet potato bowl", 510, "Black beans, sweet potato, corn and salsa; one bowl."),
            ("Edamame soba salad", 450, "Edamame, soba noodles, cabbage and sesame dressing; one bowl."),
            ("Bean and vegetable tacos", 510, "Beans, vegetables, cheese and three small tortillas.")
        ],
        "keto": [
            ("Spinach egg skillet", 390, "Eggs, spinach, mushrooms and olive oil; one skillet."),
            ("Spinach and egg skillet", 390, "Two eggs, spinach, avocado and olive oil; one plate."),
            ("Chicken avocado salad", 510, "Chicken, greens, avocado and olive oil; one bowl."),
            ("Salmon broccoli plate", 580, "Salmon, broccoli and lemon herb butter; one plate."),
            ("Salmon with broccoli", 580, "Salmon, broccoli and butter; one plate."),
            ("Turkey lettuce wraps", 430, "Turkey, lettuce, cucumber and avocado; three wraps."),
            ("Shrimp cauliflower rice", 420, "Shrimp, cauliflower rice, peppers and scallions; one bowl."),
            ("Greek chicken salad", 490, "Chicken, cucumber, tomato, feta and yogurt dressing; one bowl.")
        ],
        "protein": [
            ("Cottage cheese berry bowl", 400, "Cottage cheese, berries, oats and nuts; one bowl."),
            ("Chicken rice bowl", 580, "Chicken breast, rice, beans and vegetables; one bowl."),
            ("Turkey lentil chili", 540, "Turkey, lentils, tomatoes and vegetables; one bowl."),
            ("Tuna white bean salad", 430, "Tuna, white beans, greens and lemon olive oil; one bowl."),
            ("Salmon quinoa bowl", 560, "Salmon, quinoa, roasted vegetables and herbs; one bowl."),
            ("Egg cottage cheese toast", 390, "Eggs, cottage cheese and whole-grain toast; one plate.")
        ],
        "none": [
            ("Peanut butter overnight oats", 430, "Oats, milk, banana and peanut butter; one jar."),
            ("Chicken grain bowl", 570, "Chicken, rice, vegetables and dressing; one bowl."),
            ("Bean vegetable tacos", 510, "Beans, vegetables, cheese and three small tortillas."),
            ("Turkey hummus wrap", 460, "Turkey, hummus, whole-grain wrap and crunchy vegetables; one wrap."),
            ("Salmon sweet potato plate", 590, "Salmon, sweet potato and a green vegetable; one plate."),
            ("Vegetable egg fried rice", 500, "Eggs, brown rice, peas and mixed vegetables; one bowl.")
        ]
    };
    return [{"name": name, "calories": calories, "detail": detail} for (name, calories, detail) in menus[diet]];
}

