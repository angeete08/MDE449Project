import from ..workout_rules { completed_indices, day_energy }

def:pub ProgressCalendar(state: dict[str, any], logs: list[dict[str, any]] = []) -> JsxElement {
    has selected: str = "";
    weeks: list[dict[str, any]] = [*state.get("history", []), state, *state.get("upcoming", [])];
    chosen = [w for w in weeks if w["start_date"] == (selected or state["start_date"])];
    week = chosen[0] if len(chosen) > 0 else state;
    return <section className="progress-calendar" aria-label="Workout progress calendar">
        <div className="calendar-heading"><h3>Workout progress calendar</h3><label>Week<select aria-label="Calendar week" value={week["start_date"]} onChange={lambda (event: any) { selected = event.target.value; }}>
            {for w in weeks { <option key={w["week_id"]} value={w["start_date"]}>{"Week of " + w["start_date"]}</option> }}
        </select></label></div>
        <p>Checked exercises record progress. Difficulty feedback is separate. Saved future weeks become editable when you open that calendar week.</p>
        {week.get("routine", {}).get("goal_note") and <p>{"Confirmed goal: " + week["routine"]["goal_note"]}</p>}
        {week.get("routine", {}).get("constraints") and <aside className="injury-reminder"><strong>Your movement reminder</strong><p>{week["routine"]["constraints"] + " · Adjust effort or skip movements as needed. This note is not interpreted medically."}</p></aside>}
        <div className="calendar-grid">{for day in week["plan"] {
            done = completed_indices(week, day);
            count = len(day["exercises"]);
            energy = day_energy(state, day["date"], logs);
            <article key={day["date"]} className={"calendar-day" + (" complete" if count > 0 and len(done) == count else "")}>
                <strong>{day["day"][:3]}</strong><time>{day["date"]}</time><span>{day["title"]}</span>
                <b>{"Rest" if day["rest"] else str(len(done)) + "/" + str(count) + " complete"}</b>
                <small>{"Workouts: ≈ " + str(energy["workouts"]) + " kcal"}</small>
                <small>{"Logged activities: " + str(energy["logged"]) + " kcal"}</small>
                <strong>{"Total: " + str(energy["total"]) + " kcal"}</strong>
                {week["feedback"].get(str(day["index"])) and <small>{"Difficulty: " + week["feedback"][str(day["index"]) ]}</small>}
            </article>
        }}</div>
    </section>;
}
