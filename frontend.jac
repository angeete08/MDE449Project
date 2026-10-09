"""Jac components and browser interactions; no handwritten JavaScript."""
import from planner { create_plan, submit_feedback, restore_plan }
import from .pdf_export { download_plan_pdf }
import from .onboarding { DataSetup, clean_data_prefs, describe_data_prefs }

def:pub FitnessApp -> JsxElement {
    has goal: str = "active", experience: str = "beginner", days: str = "3",
        equipment: str = "bodyweight", diet: str = "none", calories: str = "2000",
        state: dict[str, any] = {}, status: str = "", busy: bool = False,
        dataPrefs: dict[str, any] = {}, setupOpen: bool = False;

    def remember(value: dict[str, any]) -> None {
        if not dataPrefs or not dataPrefs["store"] { return; }
        try { localStorage.setItem("stride-jac-v1", JSON.stringify(value)); }
        except Exception { status = "Plan is ready, but this browser could not save it. Download a copy to keep it."; }
    }

    async def loadSaved -> None {
        try {
            saved = localStorage.getItem("stride-jac-v1");
            if saved {
                result = await restore_plan(JSON.parse(saved) as dict[str, any]);
                status = result["message"];
                if result["ok"] {
                    restored = result["state"];
                    state = restored;
                    goal = restored["profile"]["goal"];
                    experience = restored["profile"]["experience"];
                    days = str(restored["profile"]["days"]);
                    equipment = restored["profile"]["equipment"];
                    diet = restored["profile"]["diet"];
                    calories = str(restored["profile"]["calories"]);
                }
            }
        } except Exception { status = "Saved plan could not be loaded. Create a new week, or try again after the server is available."; }
    }
    def openSetup -> None {
        try { dataPrefs = clean_data_prefs(JSON.parse(localStorage.getItem("stride-data-prefs-v1") or "null")); }
        except Exception { dataPrefs = {}; }
        if dataPrefs and dataPrefs["store"] { loadSaved(); } else { setupOpen = True; }
    }
    can with entry { openSetup(); }

    def finishSetup(prefs: dict[str, any]) -> None {
        dataPrefs = prefs;
        setupOpen = False;
        try {
            if prefs["store"] {
                localStorage.setItem("stride-data-prefs-v1", JSON.stringify(prefs));
                if state { remember(state); } else { loadSaved(); }
            } else {
                localStorage.removeItem("stride-data-prefs-v1");
                localStorage.removeItem("stride-jac-v1");
            }
        } except Exception { status = "This browser could not update saved data."; }
    }

    async def generate(e: FormEvent) -> None {
        e.preventDefault();
        if busy { return; }
        busy = True;
        try {
            profile = {"goal": goal, "experience": experience, "days": Number(days), "equipment": equipment, "diet": diet, "calories": Number(calories)};
            result = await create_plan(profile);
            status = result["message"];
            if result["ok"] {
                state = result["state"];
                remember(result["state"]);
                if not dataPrefs["store"] { status = status + " It is not stored, so it will be gone after a refresh."; }
            }
        } except Exception { status = "Could not reach the Jac server. Your current plan is unchanged; please try again."; }
        finally { busy = False; }
    }

    async def feedback(index: int, rating: str) -> None {
        if busy { return; }
        busy = True;
        try {
            result = await submit_feedback(state, index, rating);
            status = result["message"];
            if result["ok"] { state = result["state"]; remember(result["state"]); }
        } except Exception { status = "Feedback could not be saved. Please try again when the server is available."; }
        finally { busy = False; }
    }

    def downloadPdf -> None {
        if busy or not state { return; }
        try {
            download_plan_pdf(state);
            status = "Your PDF download has started.";
        } except Exception { status = "Could not create the PDF. Please try again."; }
    }

    def clearSaved -> None {
        if not window.confirm("Clear your saved profile, plan, workout feedback and data choices?") { return; }
        try { localStorage.removeItem("stride-jac-v1"); localStorage.removeItem("stride-data-prefs-v1"); }
        except Exception { status = "This browser could not clear saved data."; return; }
        state = {};
        dataPrefs = {};
        status = "Saved data cleared. Create a fresh week when you are ready.";
        setupOpen = True;
    }


    <div>
        <header><a className="brand" href="#">◈ <strong>stride</strong></a><span>GROUP 10 <b> / </b> JAC PROTOTYPE</span><div className="header-actions"><button className="quiet" onClick={lambda { setupOpen = True; }} disabled={busy}>Data settings</button><button className="quiet" onClick={clearSaved} disabled={busy}>Clear saved data</button></div></header>
        {setupOpen and <DataSetup initial={dataPrefs} onFinish={finishSetup}/>}
        <main>
            <section className="intro"><div><p className="eyebrow">A LITTLE STRUCTURE. A LOT OF MOMENTUM.</p><h1>Your week.<br/>Your pace.</h1><p className="lead">Build a routine around your goals, your equipment,<br className="desktop"/> and the life you actually have.</p></div><div className="hero-art" aria-hidden="true"><div className="orbit"/><div className="orb"/><span>MAKE ROOM<br/>FOR MOVEMENT ↗</span></div></section>
            <div className="layout">
                <aside className="panel"><div className="section-label">01 / YOUR STARTING POINT</div><h2>Make it yours</h2>
                    {bool(dataPrefs) and <p className="data-source">{describe_data_prefs(dataPrefs)}</p>}
                    <form onSubmit={generate}>
                        <label>Fitness goal<select value={goal} onChange={lambda (e: ChangeEvent) { goal = e.target.value; }}><option value="active">Stay active</option><option value="muscle">Gain muscle</option><option value="lose">Lose weight</option></select></label>
                        <label>Experience<select value={experience} onChange={lambda (e: ChangeEvent) { experience = e.target.value; }}><option value="beginner">Beginner</option><option value="intermediate">Intermediate</option><option value="advanced">Advanced</option></select></label>
                        <label>Exercise days per week<select value={days} onChange={lambda (e: ChangeEvent) { days = e.target.value; }}>{for n in range(1, 7) { <option key={n} value={str(n)}>{n}</option> }}</select></label>
                        <label>Available equipment<select value={equipment} onChange={lambda (e: ChangeEvent) { equipment = e.target.value; }}><option value="bodyweight">Bodyweight only</option><option value="dumbbells">Dumbbells</option><option value="gym">Full gym</option></select></label>
                        <label>Diet preference<select value={diet} onChange={lambda (e: ChangeEvent) { diet = e.target.value; }}><option value="none">No restriction</option><option value="vegetarian">Vegetarian</option><option value="keto">Keto</option><option value="protein">High protein</option></select></label>
                        <label>Daily calorie target <span className="optional">kcal</span><input type="number" min="1" max="10000" step="1" required={True} value={calories} onChange={lambda (e: ChangeEvent) { calories = e.target.value; }}/><small>Enter a target you have chosen. This prototype does not calculate calorie needs or a deficit.</small></label>
                        <button type="submit" className="primary" disabled={busy}>{"Building your week…" if busy else "Create my week"}<span>↗</span></button><p className="hint">Creating a plan starts a fresh week and clears workout feedback.</p>
                    </form>
                </aside>
                <section className="workspace"><div className="section-label">02 / THE PLAN</div><div className="section-top"><h2>A week you can work with</h2><button className="quiet" onClick={downloadPdf} disabled={busy or not bool(state)}>Download PDF ↓</button></div>
                    <div className="summary">
                        {if state {
                            <span><strong>{state["profile"]["days"]}</strong>{" workout days"}</span>
                            <span><strong>{state["profile"]["calories"]}</strong>{" kcal / day"}</span>
                            <span>{ {"active": "Stay active", "muscle": "Gain muscle", "lose": "Lose weight"}[state["profile"]["goal"]] }{" · "}{state["profile"]["experience"]}</span>
                            <span>{len(Object.keys(state["feedback"]))}{" workouts logged"}</span>
                        } else { <span>Set your starting point to get going.</span> }}
                    </div>
                    <p id="status" role="status" aria-live="polite">{status}</p>
                    <div className="week">
                        {if not state { <div className="empty"><div className="empty-icon">↗</div><h3>Your next step starts here.</h3><p>Choose your preferences, then create a week with exercise and room to recover.</p></div> } else {
                            for day in state["plan"] {
                                <article key={day["index"]} className={"day rest" if day["rest"] else "day"}>
                                    <div className="day-top"><span>{day["day"].upper()}</span><span className="tag">{"LOGGED" if state["feedback"][str(day["index"])] else ("RECOVERY" if day["rest"] else "WORKOUT")}</span></div>
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
                                            <button key={rating} disabled={busy or bool(state["feedback"][str(day["index"])])} aria-pressed={state["feedback"][str(day["index"])] == rating} onClick={lambda { feedback(day["index"], rating); }}>{text}</button>
                                        }}</div>
                                    }}
                                </article>
                            }
                        }}
                    </div>
                    <section className="nutrition"><div className="section-label">03 / FUEL YOUR ROUTINE</div><h2>Simple meals. More possibilities.</h2><p>{"Approximate calories per serving. These ideas do not add up to your daily target." if len(state) > 0 else "Meal ideas will follow your diet preference."}</p><div className="meals">{if state { for (i, meal) in enumerate(state["meals"]) {
                        <article key={meal["name"]} className="meal"><span className="meal-number">{"IDEA 0" + str(i + 1)}</span><h3>{meal["name"]}</h3><p>{meal["detail"]}</p><strong>{"≈ " + str(meal["calories"]) + " kcal"}</strong></article>
                    } }}</div></section>
                </section>
            </div>
            <footer><p>Jac server and UI · Demo planning rules · {"Saved on this browser" if bool(dataPrefs) and dataPrefs["store"] else "Not stored"}</p><p>Workout examples and approximate meal calories are for demonstration. Meal ideas are not a complete daily menu. Pause exercise if it causes pain.</p></footer>
        </main>
    </div>
}
