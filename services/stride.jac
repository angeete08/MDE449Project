"""Authenticated JacHammer dashboard backed by Stride's tested planner.
Health summaries are descriptive, never daily readiness or calorie prescriptions.
"""
import json;
import math;
import from datetime { date, timedelta, date as CalendarDate }
import from planner { validate_profile, create_plan, update_feedback, meal_video }

node Profile {
    has name: str = "Athlete",
        goal: str = "stay_active",
        level: str = "beginner";

    has days_per_week: int = 3,
        equipment: list[str] = [],
        diet: str = "none";

    has calorie_target: int = 2000,
        health_conditions: str = "";

    has store_data: bool = True,
        wearables: list[str] = [];

    has weekly_minutes_goal: int = 150;
    has plan_json: str = "",
        health_json: str = "";
}

obj PlanDay {
    has day: str = "",
        title: str = "",
        focus: str = "",
        date: str = "";

    has minutes: int = 0,
        calories: int = 0,
        is_rest: bool = False;

    has details: list[str] = [],
        exercises: list[dict[str, any]] = [],
        order: int = 0;

    has feedback: str = "";
}

node DailyLog {
    has date: str = "",
        steps: int = 0,
        calories_burned: int = 0;

    has run_miles: float = 0.0,
        active_minutes: int = 0;
}

obj FriendView {
    has name: str,
        points: int,
        streak: int,
        is_you: bool;
}

# Keep the browser's calendar date (rather than UTC) at week boundaries.
def calendar_date(value: str) -> date {
    day = date.fromisoformat(value);
    if day.isoformat() != value {
        raise ValueError("Use a date in YYYY-MM-DD format.");
    }
    return day;
}

def planner_profile(p: Profile) -> dict[str, any] {
    return validate_profile(
        {
            "goal": {
                "lose_weight": "lose",
                "gain_muscle": "muscle",
                "stay_active": "active"
            }[p.goal],
            "experience": p.level,
            "days": p.days_per_week,
            "equipment": "gym"
                if "gym" in p.equipment
                else ("dumbbells" if "dumbbells" in p.equipment else "bodyweight"),
            "diet": "protein" if p.diet == "high_protein" else p.diet,
            "calories": p.calorie_target,

        }
    );
}

def:priv get_profile() -> Profile | None {
    profiles = [root-->][?:Profile];
    return profiles[0] if profiles else None;
}

def require_profile() -> Profile {
    profile = get_profile();
    if profile is None {
        raise ValueError("Complete your profile first.");
    }
    return profile;
}

def:priv save_profile(
    name: str,
    goal: str,
    level: str,
    days_per_week: int,
    equipment: list[str],
    diet: str,
    calorie_target: int,
    health_conditions: str,
    store_data: bool,
    wearables: list[str],
    local_date: str = ""
) -> Profile {
    if not name.strip() or len(name.strip()) > 80 {
        raise ValueError("Enter a name of 1 to 80 characters.");
    }
    if goal not in ["lose_weight", "gain_muscle", "stay_active"] {
        raise ValueError("Choose a valid goal.");
    }
    if diet not in ["none", "vegetarian", "keto", "high_protein"] {
        raise ValueError("Choose a valid diet.");
    }
    if any(
        [
            e not in ["none", "dumbbells", "gym", "resistance bands", "yoga mat"]
            for e in equipment
        ]
    ) {
        raise ValueError("Choose supported equipment.");
    }
    if len(health_conditions) > 500 {
        raise ValueError("Keep health notes under 500 characters.");
    }
    if not store_data {
        raise ValueError("Account plans require your consent to save data.");
    }
    if local_date {
        calendar_date(local_date);
    }
    candidate = Profile(
        name=name.strip(),
        goal=goal,
        level=level,
        days_per_week=days_per_week,
        equipment=equipment,
        diet=diet,
        calorie_target=calorie_target,
        health_conditions=health_conditions,
        store_data=store_data,
        wearables=wearables
    );
    clean = planner_profile(candidate);
    p = get_profile();
    if p is None {
        result = create_plan(clean, start_date=local_date);
        if not result["ok"] {
            raise ValueError(result["message"]);
        }
        candidate.plan_json = json.dumps(result["state"]);
        root ++> candidate;
        return candidate;
    }
    p.name = candidate.name;
    p.goal = goal;
    p.level = level;
    p.days_per_week = days_per_week;
    p.equipment = equipment;
    p.diet = diet;
    p.calorie_target = calorie_target;
    p.health_conditions = health_conditions;
    p.wearables = wearables;
    p.store_data = True;
    # Existing workouts and their ratings remain exact. New preferences apply next week.
    return p;
}

def:priv get_plan_state() -> dict[str, any] {
    return json.loads(require_profile().plan_json) as dict[str, any];
}

def plan_days(state: dict[str, any]) -> list[PlanDay] {
    result: list[PlanDay] = [];
    for item in state["plan"] {
        details: list[str] = [];
        minutes = 0;
        for e in item["exercises"] {
            duration = e.get("duration", 0);
            details.append(
                e["name"]
                    + " · "
                    + (
                        str(duration) + " min"
                            if duration
                            else str(e["sets"]) + " × " + str(e["reps"])
                    )
            );
            minutes += duration;
        }
        result.append(
            PlanDay(
                day=item["day"],
                title=item["title"],
                date=item["date"],
                is_rest=item["rest"],
                details=details,
                exercises=item["exercises"],
                order=item["index"],
                minutes=minutes,
                feedback=state["feedback"].get(str(item["index"]), "")
            )
        );
    }
    return result;
}

def:priv get_plan() -> list[PlanDay] {
    return plan_days(get_plan_state());
}

def:priv regenerate_plan() -> list[PlanDay] {
    p = require_profile();
    result = create_plan(planner_profile(p), get_plan_state());
    if not result["ok"] {
        raise ValueError(result["message"]);
    }
    p.plan_json = json.dumps(result["state"]);
    return plan_days(result["state"]);
}

def:priv give_feedback(day_id: str, feedback: str) -> list[PlanDay] {
    if not day_id.isdigit() or int(day_id) not in range(7) {
        raise ValueError("Choose a workout in your plan.");
    }
    ratings = {"too_easy": "easy", "just_right": "right", "too_hard": "hard"};
    if feedback not in ratings {
        raise ValueError("Choose a valid rating.");
    }
    p = require_profile();
    state = update_feedback(get_plan_state(), int(day_id), ratings[feedback]);
    p.plan_json = json.dumps(state);
    return plan_days(state);
}

def:priv get_logs() -> list[DailyLog] {
    logs = [root-->][?:DailyLog];
    logs.sort(key=lambda (l: DailyLog) { l.date; }, reverse=True);
    return logs;
}

def validate_log(
    stamp: str,
    steps: int,
    calories_burned: int,
    run_miles: float,
    active_minutes: int,
    today: str
) {
    if calendar_date(stamp) > calendar_date(today) {
        raise ValueError("Activity logs cannot be dated in the future.");
    }
    for (value, high) in [
        (steps, 100000),
        (calories_burned, 20000),
        (active_minutes, 1440)
    ] {
        if isinstance(value, bool)
            or not isinstance(value, int)
            or not 0 <= value <= high {
            raise ValueError("Enter activity totals within the displayed limits.");
        }
    }
    if not math.isfinite(run_miles) or not 0 <= run_miles <= 200 {
        raise ValueError("Enter mileage between 0 and 200.");
    }
}

def:priv save_log(
    date: str,
    steps: int,
    calories_burned: int,
    run_miles: float,
    active_minutes: int = 0,
    today: str = ""
) -> DailyLog {
    require_profile();
    current = today if today else CalendarDate.today().isoformat();
    validate_log(date, steps, calories_burned, run_miles, active_minutes, current);
    for log in get_logs() {
        if log.date == date {
            log.steps = steps;
            log.calories_burned = calories_burned;
            log.run_miles = run_miles;
            log.active_minutes = active_minutes;
            return log;
        }
    }
    log = DailyLog(
        date=date,
        steps=steps,
        calories_burned=calories_burned,
        run_miles=run_miles,
        active_minutes=active_minutes
    );
    root ++> log;
    return log;
}

def:priv set_weekly_goal(minutes: int) -> int {
    if isinstance(minutes, bool) or not 1 <= minutes <= 10080 {
        raise ValueError("Choose a goal between 1 and 10080 minutes per week.");
    }
    require_profile().weekly_minutes_goal = minutes;
    return minutes;
}

# Pure aggregation is shared by the endpoint and calendar-boundary tests.
def activity_summary(logs: list[DailyLog], today: str, goal: int) -> dict[str, any] {
    day = calendar_date(today);
    monday = day - timedelta(days=day.weekday());
    week = [
        l
        for l in logs
        if monday <= calendar_date(l.date) <= day
    ];
    daily = [
        l
        for l in week
        if l.date == today
    ];
    minutes = sum([l.active_minutes for l in week]);
    active_dates = {
        l.date
        for l in logs
        if l.steps > 0
            or l.active_minutes > 0
            or l.run_miles > 0
            or l.calories_burned > 0
    };
    cursor = day if today in active_dates else day - timedelta(days=1);
    streak = 0;
    while cursor.isoformat() in active_dates {
        streak += 1;
        cursor -= timedelta(days=1);
    }
    return {
        "week_start": monday.isoformat(),
        "today": today,
        "weekly_minutes": minutes,
        "goal": goal,
        "remaining": max(0, goal - minutes),
        "percent": min(100, round(minutes * 100 / goal)),
        "logged_today": bool(daily),
        "steps": daily[0].steps if daily else 0,
        "active_minutes": daily[0].active_minutes if daily else 0,
        "calories_burned": daily[0].calories_burned if daily else 0,
        "run_miles": daily[0].run_miles if daily else 0.0,
        "streak": streak
    };
}

def:priv get_activity_summary(today: str) -> dict[str, any] {
    return activity_summary(get_logs(), today, require_profile().weekly_minutes_goal);
}

# Only the requesting user's data. Friends sharing is deferred until opt-in exists.
def:priv get_scoreboard() -> list[FriendView] {
    return [];
}

def:priv meal_plan() -> list[dict[str, any]] {
    # Display exactly the meal ideas retained in this week's PDF and saved state.
    catalog = get_plan_state()["meals"];
    return [
        {
            "meal": "Meal idea " + str(i + 1),
            "name": m["name"],
            "calories": m["calories"],
            "detail": m["detail"],
            "video": meal_video(m["name"], m["detail"])
        } for (i, m) in enumerate(catalog[:3])
    ];
}

def:priv save_health_summary(
    summary: dict[str, any], source: str = "Apple Health · 28-day summary"
) -> dict[str, any] {
    if source
        not in ["Apple Health · 28-day summary", "Manually entered weekly averages"] {
        raise ValueError("Choose a valid data source.");
    }
    p = require_profile();
    raw = planner_profile(p);
    for key in [
        "avg_daily_steps",
        "avg_heart_rate",
        "avg_sleep_hours",
        "avg_workouts_per_week"
    ] {
        raw[key] = summary.get(key);
    }
    clean = validate_profile(raw);
    selected = {
        key: clean[key]
        for key in [
            "avg_daily_steps",
            "avg_heart_rate",
            "avg_sleep_hours",
            "avg_workouts_per_week"
        ]
    };
    selected["source"] = source;
    p.health_json = json.dumps(selected);
    return selected;
}

def:priv get_health_summary() -> dict[str, any] {
    p = require_profile();
    return json.loads(p.health_json) as dict[str, any] if p.health_json else {};
}

def movement_break(sitting_minutes: int) -> dict[str, any] {
    if isinstance(sitting_minutes, bool) or not 0 <= sitting_minutes <= 1440 {
        raise ValueError("Enter sitting time between 0 and 1440 minutes.");
    }
    return {
        "suggested": sitting_minutes >= 60,
        "title": "Optional 3-minute movement break",
        "steps": [
            "1 minute: stand or change position comfortably",
            "1 minute: gentle shoulder rolls",
            "1 minute: easy walking or seated ankle circles"
        ],
        "note": "Based only on the sitting time you enter. Skip any movement that feels uncomfortable."
    };
}

def:priv get_movement_break(sitting_minutes: int) -> dict[str, any] {
    return movement_break(sitting_minutes);
}

def:priv clear_account_data() -> bool {
    for log in get_logs() {
        del log;
    }
    for profile in [root-->][?:Profile] {
        del profile;
    }
    return True;
}
