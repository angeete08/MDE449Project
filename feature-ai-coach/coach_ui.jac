import from .coach_profile { CoachProfile, ProfileResult, validate_profile }
import from .capture_ui { PhotoCapture }
import from .goal_ui { GoalStudio }

def:pub Coach() -> JsxElement {
    has goal: str = "general_strength", region: str = "full_body",
        experience: str = "beginner", equipment: list[str] = [],
        weekdays: list[int] = [0, 2, 4], minutes: int = 30,
        startDate: str = "", timezone: str = "UTC", constraints: str = "",
        message: str = "", errors: list[str] = [], busy: bool = False,
        activityDays: int = 0, customGoal: str = "", customStyle: str = "general_strength",
        upper: int = 1, lower: int = 1, warning: str = "", baseline: str = "";

    can with entry {
        today = new(Date);
        startDate = str(today.getFullYear()) + "-" + str(today.getMonth() + 1).zfill(2) + "-" + str(today.getDate()).zfill(2);
        browser: any = window;
        timezone = str(browser.Intl.DateTimeFormat().resolvedOptions().timeZone);
    }

    async def confirm(e: FormEvent) -> None {
        e.preventDefault();
        busy = True;
        message = "";
        errors = [];
        try {
            result = await validate_profile(CoachProfile(goal=goal, region=region, experience=experience,
                equipment=equipment, weekdays=weekdays, minutes=minutes, start_date=startDate,
                timezone=timezone, constraints=constraints, activity_days=activityDays,
                custom_goal=customGoal, custom_style=customStyle, upper_emphasis=upper, lower_emphasis=lower));
            errors = result.errors;
            warning = result.warning;
            baseline = result.baseline;
            if result.valid { message = "Preferences checked. Your confirmed focus and goal are ready for exercise planning. Nothing is saved after reload."; }
        } except Exception { errors = ["Could not reach the local coach server. Please try again."]; }
        finally { busy = False; }
    }

    <main>
        <header><a className="brand" href="#">STRIDE <span> / COACH LAB</span></a><span className="badge">Phase 3 · photo & goal studio</span></header>
        <section className="intro"><p className="eyebrow">YOUR FOCUS. YOUR PACE.</p><h1>Start with where<br/>you want to go.</h1><p>Choose a focus and a goal. Add a photo if you like.<br/>You stay in control of what comes next.</p></section>
        <div className="layout">
            <section className="card"><div className="section-title"><span className="step">01</span><div><h2>Your starting point</h2><p>A photo is optional. Manual selection always works.</p></div></div><PhotoCapture onFocus={lambda (focus: str) { region = focus; message = ""; baseline = ""; }}/></section>
            <section className="card"><div className="section-title"><span className="step">02</span><div><h2>Make it yours</h2><p>These choices guide your future exercise plan.</p></div></div>
                <form onSubmit={confirm} onChange={lambda (e: any) { message = ""; errors = []; warning = ""; baseline = ""; }}>
                    <fieldset disabled={busy}><legend>Focus and goal</legend>
                        <label>Body region<select value={region} onChange={lambda (e: ChangeEvent) { region = e.target.value; }}>
                            <option value="full_body">Full body</option><option value="shoulders">Shoulders</option><option value="arms">Arms</option><option value="chest">Chest</option><option value="back">Back</option><option value="core">Core</option><option value="glutes">Glutes</option><option value="legs">Legs</option><option value="unknown">Unsure / multiple regions</option>
                        </select></label>
                        <label>Your goal<select value={goal} onChange={lambda (e: ChangeEvent) { goal = e.target.value; }}><option value="general_strength">General strength & activity</option><option value="fat_loss">Fat-loss support</option><option value="lean_toned">Lean / toned</option><option value="muscle">Muscle building</option><option value="other">Other · customize with pictures</option></select></label>
                        <GoalStudio goal={goal} onUse={lambda (style: str, description: str, upperValue: int, lowerValue: int) { customStyle = style; customGoal = description; upper = upperValue; lower = lowerValue; message = ""; baseline = ""; warning = ""; }}/>
                        <p className="hint">You choose the goal. A photo does not measure body fat or health, and a focus region does not imply localized fat loss.</p>
                        <label>Experience<select value={experience} onChange={lambda (e: ChangeEvent) { experience = e.target.value; }}><option value="beginner">Beginner</option><option value="intermediate">Intermediate</option><option value="experienced">Experienced</option></select></label>
                    </fieldset>
                    <fieldset disabled={busy}><legend>What works for you</legend>
                        <label>Current active days per week (self-reported)<input type="number" min="0" max="7" step="1" value={activityDays} onChange={lambda (e: ChangeEvent) { activityDays = int(e.target.value); }}/></label>
                        <p className="field-title">Equipment <span className="hint">· none selected = bodyweight</span></p>
                        <div className="checks">{[<label key={item}><input type="checkbox" checked={item in equipment} onChange={lambda (e: ChangeEvent) { equipment = [x for x in equipment if x != item] if item in equipment else equipment + [item]; }}/>{item}</label> for item in ["dumbbells", "bands", "gym", "mat"]]}</div>
                        <p className="field-title">Available days</p><div className="checks">{[<label key={idx}><input type="checkbox" checked={idx in weekdays} onChange={lambda (e: ChangeEvent) { weekdays = [x for x in weekdays if x != idx] if idx in weekdays else weekdays + [idx]; }}/>{day}</label> for (idx, day) in enumerate(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])]}</div>
                        <div className="two"><label>Minutes per session<input type="number" min="10" max="120" step="1" required value={minutes} onChange={lambda (e: ChangeEvent) { minutes = int(e.target.value); }}/></label><label>Start date<input type="date" required value={startDate} onChange={lambda (e: ChangeEvent) { startDate = e.target.value; }}/></label></div>
                        <label>Timezone<input required value={timezone} onChange={lambda (e: ChangeEvent) { timezone = e.target.value; }} placeholder="America/Detroit"/></label>
                        <label>Movement preferences or constraints <span className="hint">(optional)</span><textarea maxLength={1000} value={constraints} onChange={lambda (e: ChangeEvent) { constraints = e.target.value; }} placeholder="What would you like your future plan to account for?"/></label>
                    </fieldset>
                    <div role="alert">{[<p className="error" key={error}>{error}</p> for error in errors]}</div><p role="status">{baseline}</p>{if warning { <aside className="balance-warning" role="status">{warning}</aside> }}<p className="success" role="status">{message}</p>
                    <button className="primary" type="submit" disabled={busy}>{"Checking…" if busy else "Confirm preferences"}</button>
                </form>
            </section>
        </div>
        <footer><strong>Up next</strong> Reviewed exercises and a progress calendar. Photo observations and goal pictures are starting points, not medical assessments or guaranteed results.</footer>
    </main>
}
