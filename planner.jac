"""Server-side planning rules. JSON dictionaries are the browser boundary."""
import copy;
import random;

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

def generate_week(p: dict[str, any], offset: int = 0) -> list[dict[str, any]] {
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
        reps = max(6, min(16, 10 + offset));
        duration = max(10, min(40, 20 + offset * 2));
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

def meal_ideas(diet: str, calories: int) -> list[dict[str, any]] {
    target = max(250, min(700, calories // 4));
    pool = meal_catalog(diet);
    preferred = [meal for meal in pool if abs(meal["calories"] - target) <= 220];
    choices = preferred if len(preferred) >= 3 else pool;
    available = copy.deepcopy(choices);
    selected: list[dict[str, any]] = [];
    while len(selected) < 3 {
        index = int(random.random() * len(available));
        selected.append(available.pop(index));
    }
    return selected;
}

def validate_meals(diet: str, meals: any) -> list[dict[str, any]] {
    if not isinstance(meals, list) or len(meals) != 3 { raise ValueError("Invalid saved meals."); }
    catalog = meal_catalog(diet);
    cleaned: list[dict[str, any]] = [];
    names: list[str] = [];
    for meal in meals {
        if not isinstance(meal, dict) or meal.get("name") in names { raise ValueError("Invalid saved meals."); }
        candidates = [item for item in catalog if item["name"] == meal.get("name")];
        if len(candidates) != 1 or meal.get("calories") != candidates[0]["calories"] or meal.get("detail") != candidates[0]["detail"] { raise ValueError("Invalid saved meals."); }
        names.append(meal["name"]);
        cleaned.append(copy.deepcopy(candidates[0]));
    }
    return cleaned;
}

def:pub meal_video(meal: str, detail: str) -> dict[str, any] {
    videos = {
        "Greek yogurt oat bowl": ("2vMCN-2v578", "Greek Yogurt Oatmeal Recipe", "101,321 views"),
        "Chickpea quinoa salad": ("uQ-G9Hb-H8s", "Quinoa and Chickpea salad Recipe | High Protein Vegetarian and Vegan Meal Ideas", "54,190 views"),
        "Tofu vegetable stir-fry": ("Cr4kg0jzdG4", "Sweet and sour Tofu recipe | Chilly Tofu recipe | Tofu With Stir Fry vegetable | Tofu recipe", "3,514,820 views"),
        "Lentil grain bowl": ("eQ4WNVopXV8", "Chicken And Berry Grain Bowl By Jamie Oliver", "30,161 views"),
        "Black bean sweet potato bowl": ("VWaSVPiZqD4", "Easy Black Bean & Sweet Potato Burrito Bowl Recipe | Delicious & Healthy", "214 views"),
        "Edamame soba salad": ("6PeG45T4qg8", "The Kyoto - Chicken Soba Salad", "73,162 views"),
        "Spinach egg skillet": ("BWmNcg8npqQ", "Spinach and Mushroom Egg Skillet | Quick & Easy ONE-PAN Recipe", "26,796 views"),
        "Spinach and egg skillet": ("BWmNcg8npqQ", "Spinach and Mushroom Egg Skillet | Quick & Easy ONE-PAN Recipe", "26,796 views"),
        "Chicken avocado salad": ("rzlqkJf0Wus", "Perfect CHICKEN MANGO and AVOCADO SALAD + Easy Dressing", "3,356,394 views"),
        "Salmon broccoli plate": ("XKH-F_T0-Vc", "Salmon and Broccoli Quiche Recipe", "100,329 views"),
        "Salmon with broccoli": ("PdqgZz5qnJc", "How to Make One-Pan Roasted Salmon with Broccoli and Red Potatoes", "72,353 views"),
        "Turkey lettuce wraps": ("JqtWfNBBFHY", "Turkey Club Lettuce Wraps", "56,602 views"),
        "Shrimp cauliflower rice": ("Zi6oov9ur5U", "Cauliflower Shrimp Fried Rice", "149,955 views"),
        "Greek chicken salad": ("Zh9lPzgbzJU", "Creamy chicken salad recipe with Greek yogurt dressing", "1,856,821 views"),
        "Cottage cheese berry bowl": ("ta9lWW1BOiA", "My VIRAL Cottage Cheese Bowl That Blew Up The Internet", "1,150,315 views"),
        "Chicken rice bowl": ("Sw_FsOnLuCg", "Vietnamese Lemongrass Grilled Chicken Rice Bowl", "474,040 views"),
        "Turkey lentil chili": ("z5Z2SYbMQ7E", "Turkey Lentil Chili in the Slow Cooker | Fall Recipe", "6,493 views"),
        "Tuna white bean salad": ("GXUx0eCzhpU", "Spanish White Bean & Tuna Salad | Heart-Healthy 10 Minute Recipe", "34,538 views"),
        "Salmon quinoa bowl": ("o0g_PalCTfE", "Vibrant Mediterranean Roasted Salmon and Vegetable Quinoa Bowl", "23,644 views"),
        "Egg cottage cheese toast": ("CVRFSvMrP5E", "Cottage Cheese Bread! High Protein, No Flour!", "445,625 views"),
        "Peanut butter overnight oats": ("YIS9Y1xqGdQ", "Peanut Butter Overnight Oats | Minimalist Baker Recipes", "354,355 views"),
        "Chicken grain bowl": ("yiqjzJA_VKo", "Southwest Chicken Grain Bowl", "33,356 views"),
        "Bean vegetable tacos": ("JlrVEPbLc_A", "Vegetarian Crunchy Black Bean Tacos", "109,551 views"),
        "Bean and vegetable tacos": ("JlrVEPbLc_A", "Vegetarian Crunchy Black Bean Tacos", "109,551 views"),
        "Turkey hummus wrap": ("Zy1WXNLu9aM", "Easy Turkey & Veggie Hummus Wrap", "5,498 views"),
        "Salmon sweet potato plate": ("ODE0tjJV6yc", "Cook This Amazing Salmon & Sweet Potato Plate", "3,324 views"),
        "Vegetable egg fried rice": ("g1MFKoAj0wQ", "Vegetable Fried Rice | Egg Fried Rice Recipe", "77,195 views")
    };
    video = videos.get(meal);
    if not video { return {"url": "https://www.youtube.com/results?search_query=" + meal, "thumbnail": "", "fallback": "", "title": meal, "views": ""}; }
    video_id = video[0];
    return {"url": "https://www.youtube.com/watch?v=" + video_id, "thumbnail": "https://i.ytimg.com/vi/" + video_id + "/maxresdefault.jpg", "fallback": "https://i.ytimg.com/vi/" + video_id + "/hqdefault.jpg", "title": video[1], "views": video[2]};
}

def make_state(p: dict[str, any]) -> dict[str, any] {
    clean = validate_profile(p);
    return {"profile": clean, "offset": 0, "feedback": {}, "plan": generate_week(clean), "meals": meal_ideas(clean["diet"], clean["calories"])};
}

def validate_state(state: dict[str, any]) -> dict[str, any] {
    profile = validate_profile(state.get("profile", {}));
    offset = state.get("offset", 0);
    if not isinstance(offset, int) or isinstance(offset, bool) or abs(offset) > 4 { raise ValueError("Invalid saved intensity."); }
    feedback = state.get("feedback", {});
    plan = state.get("plan", []);
    if not isinstance(feedback, dict) or not isinstance(plan, list) or len(plan) != 7 { raise ValueError("Invalid saved week."); }
    expected = generate_week(profile, offset);
    clean_plan = copy.deepcopy(expected);
    for (i, day) in enumerate(expected) {
        old = plan[i];
        if not isinstance(old, dict) or old.get("day") != day["day"] or old.get("rest") != day["rest"] or old.get("title") != day["title"] { raise ValueError("Invalid saved workout."); }
        exercises = old.get("exercises", []);
        if len(exercises) != len(day["exercises"]) { raise ValueError("Invalid saved exercises."); }
        for (j, exercise) in enumerate(day["exercises"]) {
            stored = exercises[j];
            if stored.get("name") != exercise["name"] { raise ValueError("Invalid saved exercise."); }
            metric = "duration" if "duration" in exercise else "reps";
            value = stored.get(metric);
            low = (5 if j == 1 else 10) if metric == "duration" else 6;
            high = (5 if j == 1 else 40) if metric == "duration" else 16;
            if not isinstance(value, int) or isinstance(value, bool) or not low <= value <= high { raise ValueError("Invalid saved exercise amount."); }
            clean_plan[i]["exercises"][j][metric] = value;
        }
    }
    for (key, rating) in feedback.items() {
        if key not in [str(i) for i in range(7)] or rating not in ["easy", "right", "hard"] or expected[int(key)]["rest"] { raise ValueError("Invalid saved feedback."); }
    }
    return {"profile": profile, "offset": offset, "feedback": copy.deepcopy(feedback), "plan": clean_plan, "meals": validate_meals(profile["diet"], state.get("meals", []))};
}

def update_feedback(state: dict[str, any], index: int, rating: str) -> dict[str, any] {
    clean = validate_state(state);
    if isinstance(index, bool) or not 0 <= index <= 6 or rating not in ["easy", "right", "hard"] { raise ValueError("Invalid workout feedback."); }
    key = str(index);
    if clean["plan"][index]["rest"] { raise ValueError("Choose a workout day."); }
    if key in clean["feedback"] { raise ValueError("This workout has already been logged."); }
    delta = 1 if rating == "easy" else (-1 if rating == "hard" else 0);
    clean["offset"] = max(-4, min(4, clean["offset"] + delta));
    next_week = generate_week(clean["profile"], clean["offset"]);
    for i in range(index + 1, 7) {
        if str(i) not in clean["feedback"] { clean["plan"][i] = next_week[i]; }
    }
    clean["feedback"][key] = rating;
    return clean;
}

# Explicitly public functions form the compiler-generated RPC API.
def:pub create_plan(profile: dict[str, any]) -> dict[str, any] {
    try { return {"ok": True, "state": make_state(profile), "message": "Your week is ready. Log a workout to adapt upcoming sessions."}; }
    except (ValueError, TypeError, KeyError) as error { return {"ok": False, "message": str(error)}; }
}

def:pub submit_feedback(state: dict[str, any], index: int, rating: str) -> dict[str, any] {
    try {
        message = "Workout logged. Upcoming workouts keep the same intensity.";
        if rating == "easy" { message = "Workout logged. Upcoming uncompleted workouts are slightly more challenging."; }
        elif rating == "hard" { message = "Workout logged. Upcoming uncompleted workouts are slightly gentler."; }
        return {"ok": True, "state": update_feedback(state, index, rating), "message": message};
    } except (ValueError, TypeError, KeyError, IndexError, AttributeError) as error { return {"ok": False, "message": str(error)}; }
}

def:pub restore_plan(state: dict[str, any]) -> dict[str, any] {
    try { return {"ok": True, "state": validate_state(state), "message": "Welcome back. Your plan and feedback are saved on this browser."}; }
    except (ValueError, TypeError, KeyError, IndexError, AttributeError) { return {"ok": False, "message": "No usable saved plan was found. Create a new week."}; }
}
