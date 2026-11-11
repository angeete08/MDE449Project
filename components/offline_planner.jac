import from "react" { createElement }
import from ..planning_rules { generate_week, meal_catalog }

def:pub shift_day(stamp: str, days: int) -> str {
    d: any = new(Date, stamp + "T12:00:00Z");
    d.setUTCDate(d.getUTCDate() + days);
    result: any = d.toISOString();
    return result.slice(0, 10);
}

def:pub offline_week(previous: any) -> any {
    state: any = JSON.parse(JSON.stringify(previous));
    archived: any = JSON.parse(JSON.stringify(previous));
    del archived["history"];
    history = state.history;
    history.push(archived);
    state.history = history;
    browser_crypto: any = globalThis.crypto;
    state.week_id = browser_crypto.randomUUID();
    state.source_week = previous.start_date;
    state.start_date = shift_day(previous.start_date, 7);
    state.end_date = shift_day(state.start_date, 6);
    state.starting_offsets = JSON.parse(JSON.stringify(state.offsets));
    state.feedback = {};
    state.plan = generate_week(state.profile, state.offsets.strength, state.offsets.cardio);
    for item in state.plan { item.date = shift_day(state.start_date, item.index); }
    # Keep the existing selected meal ideas; all are already valid for this diet.
    return state;
}

def:pub offline_feedback(previous: any, index: int, rating: str) -> any {
    state: any = JSON.parse(JSON.stringify(previous));
    if index < 0 or index > 6 or rating not in ["easy", "right", "hard"] {
        raise ValueError("Invalid workout rating.");
    }
    if state.plan[index].rest or state.feedback[str(index)] or state.plan[index].date > today_stamp() {
        raise ValueError( "This workout cannot be rated again.");
    }
    kind = "cardio" if state.plan[index].title == "Cardio & mobility" else "strength";
    delta = 1 if rating == "easy" else (-1 if rating == "hard" else 0);
    before = state.offsets[kind];
    state.offsets[kind] = max(-4, min(4, state.offsets[kind] + delta));
    updated: any = generate_week(state.profile, state.offsets.strength, state.offsets.cardio);
    for i in range(index + 1, 7) {
        same = (updated[i]["title"] == "Cardio & mobility") == (kind == "cardio");
        if before != state.offsets[kind] and not updated[i]["rest"] and same and not state.feedback[str(i)] {
            updated[i]["date"] = state.plan[i].date;
            state.plan[i] = updated[i];
        }
    }
    state.feedback[str(index)] = rating;
    return state;
}

def:pub today_stamp() -> str {
    d = new(Date);
    mm = str(d.getMonth() + 1);
    dd = str(d.getDate());
    return str(d.getFullYear()) + "-" + ("0" + mm if len(mm) < 2 else mm) + "-" + ("0" + dd if len(dd) < 2 else dd);
}

def:pub offline_summary(logs: any, goal: int) -> any {
    today = today_stamp();
    d: any = new(Date, today + "T12:00:00Z");
    monday = shift_day(today, 0 - ((d.getUTCDay() + 6) % 7));
    minutes = 0;
    active: any = {};
    for row in logs {
        if monday <= row.date <= today { minutes += int(row.active_minutes); }
        if row.steps > 0 or row.active_minutes > 0 or row.run_miles > 0 or row.calories_burned > 0 { active[row.date] = True; }
    }
    cursor = today if active[today] else shift_day(today, -1);
    streak = 0;
    while active[cursor] { streak += 1; cursor = shift_day(cursor, -1); }
    return {"minutes": minutes, "remaining": max(0, goal - minutes), "streak": streak};
}
