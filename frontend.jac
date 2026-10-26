"""Jac components and browser interactions; no handwritten JavaScript."""
import from planner { create_plan, submit_feedback, restore_plan, meal_video }
import from .pdf_export { download_plan_pdf }
import from .onboarding { DataSetup, clean_data_prefs, describe_data_prefs }
import from .health_panel { AppleHealthSync }
import from accounts { starter_meals, open_demo_account, read_demo_account, rename_demo_account, save_demo_plan, sync_demo_health, reset_demo_account, close_demo_account }

def:pub FitnessApp -> JsxElement {
    has goal: str = "active", experience: str = "beginner", days: str = "3",
        equipment: str = "bodyweight", diet: str = "none", calories: str = "",
        avgSteps: str = "", avgHeartRate: str = "", avgSleep: str = "", avgWorkouts: str = "",
    state: dict[str, any] = {}, mealVideos: dict[str, any] = {}, status: str = "", busy: bool = True,
    dataPrefs: dict[str, any] = {}, setupOpen: bool = False,
    historyIndex: int = -1, startDate: str = "", loadFailed: bool = False, saveWarning: str = "",
    demoToken: str = "", account: dict[str, any] = {}, accountOpen: bool = False,
    displayName: str = "", accountMessage: str = "", defaults: list[dict[str, any]] = [],
    healthSource: str = "";

    async def loadMealVideos(meals: list[dict[str, any]]) -> None {
        videos: dict[str, any] = {};
        for meal in meals { videos[meal["name"]] = await meal_video(meal["name"], meal["detail"]); }
        mealVideos = videos;
    }

    def localMonday -> str {
        today = new(Date);
        today.setHours(12, 0, 0, 0);
        today.setDate(today.getDate() - (today.getDay() + 6) % 7);
        month = today.getMonth() + 1;
        day = today.getDate();
        return str(today.getFullYear()) + "-" + ("0" if month < 10 else "") + str(month) + "-" + ("0" if day < 10 else "") + str(day);
    }

    viewed = state["history"][historyIndex] if historyIndex >= 0 else state;
    shownMeals = viewed["meals"] if state else defaults;

    async def saveAccount(value: dict[str, any]) -> None {
        try { await save_demo_plan(demoToken, value); saveWarning = ""; }
        except Exception { saveWarning = "Server saving failed. Download a PDF before signing out; reopening the demo account restores its last successful save."; }
    }

    async def remember(value: dict[str, any]) -> None {
        if demoToken { await saveAccount(value); return; }
        if not dataPrefs or not dataPrefs["store"] { return; }
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
                    await remember(restored);
                    goal = restored["profile"]["goal"];
                    experience = restored["profile"]["experience"];
                    days = str(restored["profile"]["days"]);
                    equipment = restored["profile"]["equipment"];
                    diet = restored["profile"]["diet"];
                    calories = str(restored["profile"]["calories"]);
                    avgSteps = str(restored["profile"]["avg_daily_steps"]) if restored["profile"]["avg_daily_steps"] is not None else "";
                    avgHeartRate = str(restored["profile"]["avg_heart_rate"]) if restored["profile"]["avg_heart_rate"] is not None else "";
                    avgSleep = str(restored["profile"]["avg_sleep_hours"]) if restored["profile"]["avg_sleep_hours"] is not None else "";
                    avgWorkouts = str(restored["profile"]["avg_workouts_per_week"]) if restored["profile"]["avg_workouts_per_week"] is not None else "";
                    await loadMealVideos(restored["meals"]);
                } else { loadFailed = True; }
            }
        } except Exception { loadFailed = True; status = "Saved history could not be loaded. Retry when the server is available; your stored data has not been changed."; }
        finally { busy = False; }
    }
    async def openSetup -> None {
        startDate = localMonday();
        try { dataPrefs = clean_data_prefs(JSON.parse(localStorage.getItem("stride-data-prefs-v1") or "null")); }
        except Exception { dataPrefs = {}; }
        try { defaults = await starter_meals(); await loadMealVideos(defaults); }
        except Exception { status = "Could not load starter recipes. Reload when the server is available."; }
        try {
            savedToken = sessionStorage.getItem("stride-demo-session") or "";
            if savedToken {
                demoToken = savedToken;
                await restoreAccount(await read_demo_account(savedToken, int(Date.now())));
                busy = False;
                return;
            }
        } except Exception {
            demoToken = "";
            try { sessionStorage.removeItem("stride-demo-session"); } except Exception { }
            accountMessage = "Your session ended. Open the demo account to restore server-saved data.";
        }
        if dataPrefs and dataPrefs["store"] { await loadSaved(); }
        busy = False;
    }
    can with entry { openSetup(); }

    async def finishSetup(prefs: dict[str, any]) -> None {
        dataPrefs = prefs;
        setupOpen = False;
        if prefs["source"] == "manual" { window.location.hash = "weekly-averages"; }
        try {
            if prefs["store"] {
                localStorage.setItem("stride-data-prefs-v1", JSON.stringify(prefs));
                if not demoToken {
                    if state { await remember(state); } else { await loadSaved(); }
                }
            } else {
                localStorage.removeItem("stride-data-prefs-v1");
                localStorage.removeItem("stride-jac-v1");
                localStorage.removeItem("stride-jac-v2");
            }
        } except Exception { status = "This browser could not update saved data."; }
    }

    async def generate(e: FormEvent) -> None {
        e.preventDefault();
        if busy or loadFailed { return; }
        if state and not window.confirm("Archive the current week and create the following week? Archived workouts remain viewable but cannot be rated again.") { return; }
        busy = True;
        try {
            profile = {"goal": goal, "experience": experience, "days": Number(days), "equipment": equipment, "diet": diet, "calories": Number(calories),
                "avg_daily_steps": Number(avgSteps) if avgSteps != "" else None,
                "avg_heart_rate": Number(avgHeartRate) if avgHeartRate != "" else None,
                "avg_sleep_hours": Number(avgSleep) if avgSleep != "" else None,
                "avg_workouts_per_week": Number(avgWorkouts) if avgWorkouts != "" else None};
            result = await create_plan(profile, state, startDate);
            status = result["message"];
            if result["ok"] {
                state = result["state"];
                historyIndex = -1;
                mealVideos = {};
                await remember(result["state"]);
                await loadMealVideos(result["state"]["meals"]);
                if not demoToken and (not dataPrefs or not dataPrefs["store"]) { status = status + " It is not stored, so it will be gone after a refresh."; }
            }
        } except Exception { status = "Could not reach the Jac server. Your current plan is unchanged; please try again."; }
        finally { busy = False; }
    }

    async def feedback(index: int, rating: str) -> None {
        if busy or historyIndex >= 0 { return; }
        busy = True;
        try {
            result = await submit_feedback(state, index, rating);
            status = result["message"];
            if result["ok"] { state = result["state"]; historyIndex = -1; await remember(result["state"]); }
        } except Exception { status = "Feedback could not be saved. Please try again when the server is available."; }
        finally { busy = False; }
    }

    def useHealthSummary(summary: dict[str, any]) -> None {
        # Each sync replaces the previous summary, including unavailable metrics.
        avgSteps = "";
        avgHeartRate = "";
        avgSleep = "";
        avgWorkouts = "";
        healthSource = "Apple Health · 28-day summary";
        filled: list[str] = [];
        if summary["avg_daily_steps"] is not None { avgSteps = str(summary["avg_daily_steps"]); filled.append("steps"); }
        if summary["avg_heart_rate"] is not None { avgHeartRate = str(summary["avg_heart_rate"]); filled.append("heart rate"); }
        if summary["avg_sleep_hours"] is not None { avgSleep = str(summary["avg_sleep_hours"]); filled.append("sleep"); }
        if summary["avg_workouts_per_week"] is not None { avgWorkouts = str(summary["avg_workouts_per_week"]); filled.append("workouts"); }
        status = ("Filled from Apple Health: " + ", ".join(filled) + ". Missing values are left blank.") if len(filled) > 0 else "Apple Health returned no steps, heart rate, sleep or workouts for the last 28 days. All average fields were cleared; enter any averages manually.";
        window.location.hash = "weekly-averages";
    }

    async def restoreAccount(value: dict[str, any]) -> None {
        await clearView();
        account = value;
        displayName = value["name"];
        state = {};
        historyIndex = -1;
        loadFailed = False;
        saveWarning = "";
        if bool(value["plan"]) {
            result = await restore_plan(value["plan"], localMonday());
            if not result["ok"] { loadFailed = True; status = result["message"]; return; }
            restored = result["state"];
            state = restored;
            goal = restored["profile"]["goal"];
            experience = restored["profile"]["experience"];
            days = str(restored["profile"]["days"]);
            equipment = restored["profile"]["equipment"];
            diet = restored["profile"]["diet"];
            calories = str(restored["profile"]["calories"]);
            avgSteps = str(restored["profile"]["avg_daily_steps"]) if restored["profile"]["avg_daily_steps"] is not None else "";
            avgHeartRate = str(restored["profile"]["avg_heart_rate"]) if restored["profile"]["avg_heart_rate"] is not None else "";
            avgSleep = str(restored["profile"]["avg_sleep_hours"]) if restored["profile"]["avg_sleep_hours"] is not None else "";
            avgWorkouts = str(restored["profile"]["avg_workouts_per_week"]) if restored["profile"]["avg_workouts_per_week"] is not None else "";
            healthSource = "Saved profile averages · review or sync again to verify their source";
            await loadMealVideos(restored["meals"]);
        }
        status = "Demo account connected. Plans and feedback save on this server. Starter recipes need no profile.";
    }

    async def connectAccount -> None {
        busy = True;
        try {
            result = await open_demo_account();
            demoToken = result["token"];
            try { sessionStorage.setItem("stride-demo-session", demoToken); }
            except Exception { accountMessage = "Session storage is unavailable. Reconnect after refreshing."; }
            await restoreAccount(result["account"]);
            accountMessage = "Connected to the shared local demo account.";
        } except Exception { accountMessage = "Could not connect to the demo account. Check the Jac server and try again."; }
        finally { busy = False; }
    }

    async def renameAccount(e: FormEvent) -> None {
        e.preventDefault();
        busy = True;
        try {
            account = await rename_demo_account(demoToken, displayName);
            displayName = account["name"];
            accountMessage = "Display name saved on the server.";
        } except Exception { accountMessage = "Could not save. Use 1–60 characters, or reconnect if the session expired."; }
        finally { busy = False; }
    }

    async def testSync -> None {
        busy = True;
        try {
            summary = await sync_demo_health(demoToken);
            avgSteps = str(summary["avg_daily_steps"]);
            avgHeartRate = str(summary["avg_heart_rate"]);
            avgSleep = str(summary["avg_sleep_hours"]);
            avgWorkouts = str(summary["avg_workouts_per_week"]);
            account = await read_demo_account(demoToken, int(Date.now()));
            healthSource = "Synthetic server test data · 28-day example";
            accountMessage = "Test connection synced: 7,200 steps/day, 72 bpm, 7.5 hours sleep, 3 workouts/week. Review the form before creating a plan.";
        } except Exception { accountMessage = "Test sync failed. Reconnect to the demo account and try again."; }
        finally { busy = False; }
    }

    async def clearView -> None {
        state = {}; historyIndex = -1; calories = "";
        avgSteps = ""; avgHeartRate = ""; avgSleep = ""; avgWorkouts = "";
        goal = "active"; experience = "beginner"; days = "3"; equipment = "bodyweight"; diet = "none";
        healthSource = ""; loadFailed = False; saveWarning = "";
        await loadMealVideos(defaults);
    }

    async def signOut -> None {
        busy = True;
        try {
            await close_demo_account(demoToken);
            try { sessionStorage.removeItem("stride-demo-session"); } except Exception { }
            demoToken = ""; account = {}; displayName = "";
            await clearView();
            accountMessage = "Signed out. Your demo data remains on this server.";
            status = "Browse starter meals or reconnect to your demo account.";
        } except Exception { accountMessage = "Could not sign out. Check the server connection and retry."; }
        finally { busy = False; }
    }

    async def resetAccount -> None {
        if not window.confirm("Reset the shared demo account? This deletes its server-saved plan, history, health test data and display name.") { return; }
        busy = True;
        try {
            account = await reset_demo_account(demoToken);
            displayName = account["name"];
            await clearView();
            accountMessage = "Demo account reset. Starter recipes are ready.";
            status = "Demo account reset.";
        } except Exception { accountMessage = "Could not reset the account. Reconnect and try again."; }
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
        if not window.confirm("Clear this browser's saved profile, plan, feedback and data choices? The server demo account is managed separately in Account.") { return; }
        try { localStorage.removeItem("stride-jac-v1"); localStorage.removeItem("stride-jac-v2"); localStorage.removeItem("stride-data-prefs-v1"); }
        except Exception { status = "This browser could not clear saved data."; return; }
        if demoToken { dataPrefs = {}; status = "Browser data cleared. The demo account on this server is unchanged."; return; }
        state = {};
        mealVideos = {};
        dataPrefs = {};
        historyIndex = -1;
        loadFailed = False;
        saveWarning = "";
        status = "Saved data cleared. Create a fresh week when you are ready.";
        setupOpen = True;
    }


    <div>
        <header><a className="brand stride-brand" href="#" aria-label="Stride home"><span className="stride-brand-wordmark" role="img" aria-label="STRIDE wordmark from Logo 1"/></a><span>GROUP 10 <b> / </b> JAC PROTOTYPE</span><div className="header-actions"><button className="quiet" onClick={lambda { accountOpen = True; }} disabled={busy}>{account["name"] if bool(account) else "Account"}</button><button className="quiet" onClick={lambda { setupOpen = True; }} disabled={busy}>Data settings</button><button className="quiet" onClick={clearSaved} disabled={busy}>Clear browser data</button></div></header>
        {if accountOpen {
            <div className="modal-backdrop"><section className="modal" role="dialog" aria-modal="true" aria-labelledby="account-title">
                <div className="section-label">SINGLE-USER DEMO</div><h2 id="account-title">Your Stride account</h2>
                {if account {
                    <p>{account["email"]}{" · Shared local demo"}</p>
                    <form onSubmit={renameAccount}><label>Display name<input value={displayName} maxLength={60} required={True} onChange={lambda (e: ChangeEvent) { displayName = e.target.value; }}/></label><button className="primary" disabled={busy}>Save display name</button></form>
                    <div className="account-connection"><h3>Server test connection</h3><p>Synthetic health data for the demo. No wearable account, external API or iPhone is required.</p><button className="quiet" onClick={testSync} disabled={busy}>Sync test data</button>{if bool(account["health"]) { <p>Test summary saved on this server. Sync again to fill the form.</p> }}</div>
                    <p>Plans, workout feedback and test summaries are saved on this computer's server. Your session expires after 12 hours or a server restart.</p>
                    <div className="account-actions"><button className="quiet" onClick={signOut} disabled={busy}>Sign out</button><button className="quiet" onClick={resetAccount} disabled={busy}>Reset demo account</button></div>
                } else {
                    <p>Open the shared demo account to save plans and feedback on this server and try a synthetic health connection. Everyone using this local demo sees the same account. Existing browser plans are kept separately.</p>
                    <button className="primary" onClick={connectAccount} disabled={busy}>Open demo account &amp; enable server saving</button>
                }}
                <p role="status" aria-live="polite">{accountMessage}</p>
                <button className="quiet" onClick={lambda { accountOpen = False; }} disabled={busy}>Close account</button>
            </section></div>
        }}
        {setupOpen and <DataSetup initial={dataPrefs} onFinish={finishSetup} serverSaving={bool(demoToken)}/>}
        <main>
            <section className="intro"><div><p className="eyebrow">A LITTLE STRUCTURE. A LOT OF MOMENTUM.</p><h1>Your week.<br/>Your pace.</h1><p className="lead">Build a routine around your goals, your equipment,<br className="desktop"/> and the life you actually have.</p></div><div className="hero-art hero-logo" role="img" aria-label="Stride Logo 2: athlete lifting a dumbbell"/></section>
            <div className="layout">
                <aside className="panel"><div className="section-label">01 / YOUR STARTING POINT</div><h2>Make it yours</h2>
                    <p className="hint">Starter recipes are ready below. Customize this form only when you want a workout plan.</p>
                    {if account { <p className="data-source">{"Demo account: " + account["name"] + " · Plans save on this server"}</p> }}
                    {bool(dataPrefs) and <p className="data-source">{describe_data_prefs(dataPrefs)}</p>}
                    <form onSubmit={generate}>
                        <h3 id="weekly-averages">Weekly averages <span className="optional">optional</span></h3>
                        <p className="hint">Enter only the values available from your app.</p>
                        {if healthSource { <p className="data-source">{healthSource}</p> }}
                        {if bool(dataPrefs) and dataPrefs["hub"] == "apple" { <AppleHealthSync onSynced={useHealthSummary}/> }}
                        <label>Average daily steps<input type="number" min="0" max="100000" step="1" required={False} value={avgSteps} onChange={lambda (e: ChangeEvent) { avgSteps = e.target.value; }}/></label>
                        <label>Average heart rate <span className="optional">bpm</span><input type="number" min="20" max="250" step="0.1" required={False} value={avgHeartRate} onChange={lambda (e: ChangeEvent) { avgHeartRate = e.target.value; }}/></label>
                        <label>Average sleep per night <span className="optional">hours</span><input type="number" min="0" max="24" step="0.1" required={False} value={avgSleep} onChange={lambda (e: ChangeEvent) { avgSleep = e.target.value; }}/></label>
                        <label>Average workouts per week<input type="number" min="0" max="50" step="0.1" required={False} value={avgWorkouts} onChange={lambda (e: ChangeEvent) { avgWorkouts = e.target.value; }}/></label>
                        <h3>Plan preferences</h3>
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
                            <small>{len(state["history"])}{" archived weeks · "}{"Saved to the demo account on this server." if demoToken else ("Saved in this browser only." if dataPrefs and dataPrefs["store"] else "Not stored after refresh.")}</small>
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
                    {if loadFailed { <button className="quiet" onClick={lambda { if demoToken { accountOpen = True; } else { loadSaved(); } }} disabled={busy}>Retry loading saved history</button> }}
                    <div className="week">
                        {if not state { <div className="empty"><div className="empty-icon">↗</div><h3>Your next step starts here.</h3><p>Choose your preferences, then create a week with exercise and room to recover.</p></div> } else {
                            for day in viewed["plan"] {
                                <article key={day["index"]} className={"day rest" if day["rest"] else "day"}>
                                    <div className="day-top"><span>{day["day"].upper()}<small>{day["date"]}</small></span><span className="tag">{"LOGGED" if viewed["feedback"][str(day["index"])] else ("RECOVERY" if day["rest"] else "WORKOUT")}</span></div>
                                    <h3>{day["title"]}</h3>
                                    {if not day["rest"] {
                                        <p>Start with 5 minutes of gentle movement.</p>
                                        for exercise in day["exercises"] {
                                            <div key={exercise["name"]} className="exercise"><a className="exercise-name" href={"https://www.youtube.com/results?search_query=" + encodeURIComponent(exercise["name"] + " exercise tutorial")} target="_blank" rel="noreferrer">{exercise["name"]}</a><span>{str(exercise["duration"]) + " min" if exercise["duration"] else str(exercise["sets"]) + " × " + str(exercise["reps"])}</span></div>
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
                    <section className="nutrition"><div className="section-label">03 / FUEL YOUR ROUTINE</div><h2>Simple meals. More possibilities.</h2><p>{"Approximate calories per serving. These ideas do not add up to your daily target." if len(state) > 0 else "Starter recipes · No profile needed. These examples are not personalized. Approximate calories per serving."}</p><div className="meals">{for (i, meal) in enumerate(shownMeals) {
                        <article key={meal["name"]} className="meal"><span className="meal-number">{"IDEA 0" + str(i + 1)}</span><h3><a className="meal-name" href={"https://www.youtube.com/results?search_query=" + encodeURIComponent(meal["name"] + " recipe video")} target="_blank" rel="noreferrer">{meal["name"]}</a></h3><p>{meal["detail"]}</p>{if mealVideos.get(meal["name"], {}).get("thumbnail") { <a className="meal-video" href={mealVideos[meal["name"]]["url"]} target="_blank" rel="noreferrer"><img src={mealVideos[meal["name"]]["thumbnail"]} onError={lambda (e: any) { e.currentTarget.src = mealVideos[meal["name"]]["fallback"]; }} alt={"YouTube video: " + mealVideos[meal["name"]]["title"]}/></a> }}<strong>{"≈ " + str(meal["calories"]) + " kcal"}</strong></article>
                    } }</div></section>
                </section>
            </div>
            <footer><p>Jac server and UI · Demo planning rules · {"Saved on this server · shared demo account" if demoToken else ("Saved on this browser" if bool(dataPrefs) and dataPrefs["store"] else "Not stored")}</p><p>Workout examples and approximate meal calories are for demonstration. Meal ideas are not a complete daily menu. Pause exercise if it causes pain.</p></footer>
        </main>
    </div>
}
