"""Jac components and browser interactions; no handwritten JavaScript."""
import from planner { create_plan, submit_feedback, restore_plan }
import from .pdf_export { download_plan_pdf }

def:pub FitnessApp -> JsxElement {
    has goal: str = "active", experience: str = "beginner", days: str = "3",
        equipment: str = "bodyweight", diet: str = "none", calories: str = "2000",
        state: dict[str, any] = {}, status: str = "", busy: bool = True,
        historyIndex: int = -1, startDate: str = "", loadFailed: bool = False, saveWarning: str = "";

    viewed = state["history"][historyIndex] if historyIndex >= 0 else state;

    def localMonday -> str {
        today = new(Date);
        today.setHours(12, 0, 0, 0);
        today.setDate(today.getDate() - (today.getDay() + 6) % 7);
        month = today.getMonth() + 1;
        day = today.getDate();
        return str(today.getFullYear()) + "-" + ("0" if month < 10 else "") + str(month) + "-" + ("0" if day < 10 else "") + str(day);
    }

    def remember(value: dict[str, any]) -> None {
        try { localStorage.setItem("stride-jac-v2", JSON.stringify(value)); saveWarning = ""; }
        except Exception { saveWarning = "Changes are only in this tab: browser storage failed or is full. Keep this tab open and download a PDF for your records."; }
    }

    async def loadSaved -> None {
        busy = True;
        loadFailed = False;
        startDate = localMonday();
        try {
            saved = localStorage.getItem("stride-jac-v2") or localStorage.getItem("stride-jac-v1");
            if saved {
                result = await restore_plan(JSON.parse(saved) as dict[str, any], startDate);
                status = result["message"];
                if result["ok"] {
                    restored = result["state"];
                    state = restored;
                    historyIndex = -1;
                    remember(restored);
                    goal = restored["profile"]["goal"];
                    experience = restored["profile"]["experience"];
                    days = str(restored["profile"]["days"]);
                    equipment = restored["profile"]["equipment"];
                    diet = restored["profile"]["diet"];
                    calories = str(restored["profile"]["calories"]);
                } else { loadFailed = True; }
            }
        } except Exception { loadFailed = True; status = "Saved history could not be loaded. Retry when the server is available; your stored data has not been changed."; }
        finally { busy = False; }
    }
    can with entry { loadSaved(); }

    async def generate(e: FormEvent) -> None {
        e.preventDefault();
        if busy or loadFailed { return; }
        if state and not window.confirm("Archive the current week and create the following week? Archived workouts remain viewable but cannot be rated again.") { return; }
        busy = True;
        try {
            profile = {"goal": goal, "experience": experience, "days": Number(days), "equipment": equipment, "diet": diet, "calories": Number(calories)};
            result = await create_plan(profile, state, startDate);
            status = result["message"];
            if result["ok"] { state = result["state"]; historyIndex = -1; remember(result["state"]); }
        } except Exception { status = "Could not reach the Jac server. Your current plan is unchanged; please try again."; }
        finally { busy = False; }
    }

    async def feedback(index: int, rating: str) -> None {
        if busy or historyIndex >= 0 { return; }
        busy = True;
        try {
            result = await submit_feedback(state, index, rating);
            status = result["message"];
            if result["ok"] { state = result["state"]; historyIndex = -1; remember(result["state"]); }
        } except Exception { status = "Feedback could not be saved. Please try again when the server is available."; }
        finally { busy = False; }
    }

    def downloadPdf -> None {
        if busy or not state { return; }
        try {
            download_plan_pdf(viewed);
            status = "Your PDF download has started.";
        } except Exception { status = "Could not create the PDF. Please try again."; }
    }

    def clearSaved -> None {
        if not window.confirm("Permanently clear your profile, current plan, ALL archived weeks and feedback?") { return; }
        try { localStorage.removeItem("stride-jac-v1"); localStorage.removeItem("stride-jac-v2"); }
        except Exception { status = "This browser could not clear saved data."; return; }
        state = {};
        historyIndex = -1;
        loadFailed = False;
        saveWarning = "";
        status = "Saved data cleared. Create a fresh week when you are ready.";
    }


    <div>
        <header><a className="brand" href="#">◈ <strong>stride</strong></a><span>GROUP 10 <b> / </b> JAC PROTOTYPE</span><button className="quiet" onClick={clearSaved} disabled={busy}>Clear saved data</button></header>
        <main>
            <section className="intro"><div><p className="eyebrow">A LITTLE STRUCTURE. A LOT OF MOMENTUM.</p><h1>Your week.<br/>Your pace.</h1><p className="lead">Build a routine around your goals, your equipment,<br className="desktop"/> and the life you actually have.</p></div><div className="hero-art" aria-hidden="true"><div className="orbit"/><div className="orb"/><span>MAKE ROOM<br/>FOR MOVEMENT ↗</span></div></section>
            <div className="layout">
                <aside className="panel"><div className="section-label">01 / YOUR STARTING POINT</div><h2>Make it yours</h2>
                    <form onSubmit={generate}>
                        <label>Fitness goal<select value={goal} onChange={lambda (e: ChangeEvent) { goal = e.target.value; }}><option value="active">Stay active</option><option value="muscle">Gain muscle</option><option value="lose">Lose weight</option></select></label>
                        <label>Experience<select value={experience} onChange={lambda (e: ChangeEvent) { experience = e.target.value; }}><option value="beginner">Beginner</option><option value="intermediate">Intermediate</option><option value="advanced">Advanced</option></select></label>
                        <label>Exercise days per week<select value={days} onChange={lambda (e: ChangeEvent) { days = e.target.value; }}>{for n in range(1, 7) { <option key={n} value={str(n)}>{n}</option> }}</select></label>
                        <label>Available equipment<select value={equipment} onChange={lambda (e: ChangeEvent) { equipment = e.target.value; }}><option value="bodyweight">Bodyweight only</option><option value="dumbbells">Dumbbells</option><option value="gym">Full gym</option></select></label>
                        <label>Diet preference<select value={diet} onChange={lambda (e: ChangeEvent) { diet = e.target.value; }}><option value="none">No restriction</option><option value="vegetarian">Vegetarian</option><option value="keto">Keto</option><option value="protein">High protein</option></select></label>
                        <label>Daily calorie target <span className="optional">kcal</span><input type="number" min="1" max="10000" step="1" required={True} value={calories} onChange={lambda (e: ChangeEvent) { calories = e.target.value; }}/><small>Enter a target you have chosen. This prototype does not calculate calorie needs or a deficit.</small></label>
                        {if not state { <label>Week starting (Monday)<input type="date" required={True} value={startDate} onChange={lambda (e: ChangeEvent) { startDate = e.target.value; }}/><small>A selected date is aligned to its Monday.</small></label> }}
                        <button type="submit" className="primary" disabled={busy or loadFailed}>{"Please wait…" if busy else ("Create next week" if bool(state) else "Create my week")}<span>↗</span></button><p className="hint">Creating the next week archives this week and carries forward strength and cardio difficulty separately. Form changes apply to the new week.</p>
                    </form>
                </aside>
                <section className="workspace"><div className="section-label">02 / THE PLAN</div><div className="section-top"><h2>A week you can work with</h2><button className="quiet" onClick={downloadPdf} disabled={busy or not bool(state)}>Download PDF ↓</button></div>
                    {if state {
                        <div className="memory-panel">
                            <label>View a week<select value={str(historyIndex)} disabled={busy} onChange={lambda (e: ChangeEvent) { historyIndex = int(e.target.value); }}>
                                <option value="-1">{"Current: " + state["start_date"] + " to " + state["end_date"]}</option>
                                {for (i, week) in enumerate(state["history"]) { <option key={week["week_id"]} value={str(i)}>{"Archived: " + week["start_date"] + " to " + week["end_date"]}</option> }}
                            </select></label>
                            <h3>{viewed["start_date"]}{" to "}{viewed["end_date"]}</h3>
                            <p>{viewed["memory_note"]}</p>
                            <p><strong>Saved difficulty for the next week:</strong>{" "}{10 + viewed["offsets"]["strength"]}{" strength reps / "}{20 + 2 * viewed["offsets"]["cardio"]}{" cardio minutes."}</p>
                            <small>{len(state["history"])}{" archived weeks · Saved in this browser only."}</small>
                            {if historyIndex >= 0 { <p className="archive-notice">Archived week: read-only. Download PDF exports this selected week.</p> }}
                        </div>
                    }}
                    <div className="summary">
                        {if state {
                            <span><strong>{viewed["profile"]["days"]}</strong>{" workout days"}</span>
                            <span><strong>{viewed["profile"]["calories"]}</strong>{" kcal / day"}</span>
                            <span>{ {"active": "Stay active", "muscle": "Gain muscle", "lose": "Lose weight"}[viewed["profile"]["goal"]] }{" · "}{viewed["profile"]["experience"]}</span>
                            <span>{len(Object.keys(viewed["feedback"]))}{" workouts logged"}</span>
                        } else { <span>Set your starting point to get going.</span> }}
                    </div>
                    <p id="status" role="status" aria-live="polite">{status}</p>
                    {if saveWarning { <p className="archive-notice" role="alert">{saveWarning}</p> }}
                    {if loadFailed { <button className="quiet" onClick={lambda { loadSaved(); }} disabled={busy}>Retry loading saved history</button> }}
                    <div className="week">
                        {if not state { <div className="empty"><div className="empty-icon">↗</div><h3>Your next step starts here.</h3><p>Choose your preferences, then create a week with exercise and room to recover.</p></div> } else {
                            for day in viewed["plan"] {
                                <article key={day["index"]} className={"day rest" if day["rest"] else "day"}>
                                    <div className="day-top"><span>{day["day"].upper()}<small>{day["date"]}</small></span><span className="tag">{"LOGGED" if viewed["feedback"][str(day["index"])] else ("RECOVERY" if day["rest"] else "WORKOUT")}</span></div>
                                    <h3>{day["title"]}</h3>
                                    {if not day["rest"] {
                                        <p>Start with 5 minutes of gentle movement.</p>
                                        for exercise in day["exercises"] {
                                            <div key={exercise["name"]} className="exercise"><span>{exercise["name"]}</span><span>{str(exercise["duration"]) + " min" if exercise["duration"] else str(exercise["sets"]) + " × " + str(exercise["reps"])}</span></div>
                                        }
                                    }}
                                    <p>{day["note"]}</p>
                                    {if not day["rest"] {
                                        <p>After this workout, how did it feel?</p>
                                        <div className="feedback">{for (rating, text) in [("easy", "Too easy"), ("right", "Just right"), ("hard", "Too hard")] {
                                            <button key={rating} disabled={busy or historyIndex >= 0 or bool(viewed["feedback"][str(day["index"])])} aria-pressed={viewed["feedback"][str(day["index"])] == rating} onClick={lambda { feedback(day["index"], rating); }}>{text}</button>
                                        }}</div>
                                    }}
                                </article>
                            }
                        }}
                    </div>
                    <section className="nutrition"><div className="section-label">03 / FUEL YOUR ROUTINE</div><h2>Simple meals. More possibilities.</h2><p>{"Approximate calories per serving. These ideas do not add up to your daily target." if len(state) > 0 else "Meal ideas will follow your diet preference."}</p><div className="meals">{if state { for (i, meal) in enumerate(viewed["meals"]) {
                        <article key={meal["name"]} className="meal"><span className="meal-number">{"IDEA 0" + str(i + 1)}</span><h3>{meal["name"]}</h3><p>{meal["detail"]}</p><strong>{"≈ " + str(meal["calories"]) + " kcal"}</strong></article>
                    } }}</div></section>
                </section>
            </div>
            <footer><p>Jac server and UI · Demo planning rules · Saved on this browser</p><p>Workout examples and approximate meal calories are for demonstration. Meal ideas are not a complete daily menu. Pause exercise if it causes pain.</p></footer>
        </main>
    </div>
}
