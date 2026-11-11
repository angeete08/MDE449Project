import from .offline_planner { offline_week, offline_feedback, today_stamp, offline_summary }
import from "react" { useEffect }
import from "@jac/runtime" { Link, jacLogout }
import from .offline_store { read_offline, write_offline, erase_offline, clear_for_logout, export_offline }
import from ..services.offline { offline_snapshot, sync_offline_change }
import from ..pdf_export { download_plan_pdf }

# The offline page intentionally does not require a live auth check: the user
# explicitly opted into a readable copy on this device. Server replay always authenticates.
def:pub OfflineApp() -> JsxElement {
    has doc: any = None, message: str = "", busy: bool = False, consent: bool = False;
    has online: bool = True, stamp: str = "", steps: str = "0", minutes: str = "0",
        calories: str = "0", miles: str = "0", goal: str = "150", sitting: str = "60";
    has show_break: bool = False;
    can with entry {
        try { doc = read_offline(); }
        except Exception { message = "Device storage could not be read. It may be unavailable or damaged."; }
        d = new(Date);
        mm = str(d.getMonth() + 1);
        dd = str(d.getDate());
        stamp = str(d.getFullYear()) + "-" + ("0" + mm if len(mm) < 2 else mm) + "-" + ("0" + dd if len(dd) < 2 else dd);
        if doc {
            goal = str(doc.snapshot["goal"]);
            for item in doc.pending { if item.kind == "goal" { goal = str(item.value); } }
        }
    }
    useEffect(lambda {
        changed = lambda { online = navigator.onLine; };
        online = navigator.onLine;
        storage_changed = lambda {
            try { doc = read_offline(); } except Exception { message = "Could not read the updated device copy."; }
        };
        window.addEventListener("storage", storage_changed);
        window.addEventListener("online", changed);
        window.addEventListener("offline", changed);
        return lambda {
            window.removeEventListener("storage", storage_changed);
            window.removeEventListener("online", changed);
            window.removeEventListener("offline", changed);
        };
    }, []);

    async def save_copy() {
        if busy { return; }
        if doc and len(doc.pending) > 0 {
            message = "Sync or discard pending drafts before refreshing the device copy.";
            return;
        }
        if not doc and not consent { message = "Enable device storage below before saving a copy."; return; }
        busy = True;
        try {
            snapshot = await offline_snapshot();
            if doc and doc.snapshot["owner"] != snapshot["owner"] {
                message = "This copy belongs to a different account. Erase it before saving this account.";
                return;
            }
            candidate = {"version": 1, "snapshot": snapshot, "pending": [], "revision": doc.revision if doc else ""};
            doc = write_offline(candidate);
            goal = str(snapshot["goal"]);
            message = "Device copy saved. Keep this page bookmarked for offline use.";
        } except Exception { message = "Could not save a copy. Sign in online, finish your profile, and check device storage."; }
        finally { busy = False; }
    }

    def queue(change: any) {
        try {
            pending: list[any] = [];
            for item in doc.pending {
                if item.kind == change.kind and item.key == change.key {
                    change.base = item.base;
                } else { pending.append(item); }
            }
            pending.append(change);
            doc = write_offline({**doc, "pending": pending});
            message = "Draft saved on this device. It has not been sent to the server.";
        } except Exception { message = "Could not save the draft. Storage may be full, or another tab changed this copy. Reload before trying again."; }
    }

    def save_log_draft() {
        if not stamp or stamp > today_stamp() or not steps.isdigit() or not minutes.isdigit() or not calories.isdigit()
            or not miles.replace(".", "", 1).isdigit() {
            message = "Enter a date and nonnegative activity numbers."; return;
        }
        if int(steps) > 100000 or int(minutes) > 1440 or int(calories) > 20000 or float(miles) > 200 {
            message = "Limits: 100000 steps, 1440 minutes, 20000 kcal, 200 miles."; return;
        }
        base: any = None;
        for item in doc.snapshot.logs { if item.date == stamp { base = item; } }
        queue({"kind": "log", "key": stamp, "base": base, "value": {"date": stamp,
            "steps": int(steps), "active_minutes": int(minutes), "calories_burned": int(calories), "run_miles": float(miles)}});
    }

    def rate(day: any, value: str) {
        base = working_state.feedback[str(day.index)] or "";
        try {
            updated = offline_feedback(working_state, int(day.index), value);
            queue({"kind": "plan", "key": "plan", "base": doc.snapshot.state, "value": updated});
        } except Exception { message = "Only today's or earlier unlogged workouts can be rated."; }
    }

    async def sync() {
        if busy or not doc { return; }
        busy = True;
        try {
            # Re-read to detect another tab's edits before sending anything.
            current = read_offline();
            if not current or current.revision != doc.revision {
                message = "Another tab changed this copy. Reload before syncing."; return;
            }
            while len(doc.pending) > 0 {
                item = doc.pending[0];
                result = await sync_offline_change(doc.snapshot["owner"], item);
                if result["status"] == "conflict" {
                    message = "Sync stopped: the server has a newer value or different workout week. Your draft is kept below. Discard that draft to keep the server value, then sync again.";
                    return;
                }
                if result["status"] not in ["applied", "already_applied"] {
                    message = "Unexpected sync response. Draft kept; try again later."; return;
                }
                confirmed: any = JSON.parse(JSON.stringify(doc.snapshot));
                value: any = result["value"] if result["status"] == "applied" else result["current"];
                if item.kind == "goal" { confirmed.goal = value; }
                if item.kind == "plan" { confirmed.state = value; }
                if item.kind == "log" {
                    confirmed.logs = [*confirmed.logs.filter(lambda (row: any) { return row.date != item.key; }), value];
                }
                doc = write_offline({**doc, "snapshot": confirmed, "pending": doc.pending.slice(1)});
            }
            snapshot = await offline_snapshot();
            if snapshot["owner"] != doc.snapshot["owner"] {
                message = "Account changed. Device copy was not replaced."; return;
            }
            doc = write_offline({**doc, "snapshot": snapshot});
            message = "All drafts synced and the device copy refreshed.";
        } except Exception {
            message = "Sync paused. Remaining drafts are kept. Check your connection and sign in to the original account. The server may also reject an invalid date or already-rated workout.";
        } finally { busy = False; }
    }

    async def restore_backup(e: any) {
        file = e.target.files[0];
        if not file or busy { return; }
        if file.size > 4000000 { message = "Backup exceeds the 4 MB limit."; return; }
        if not window.confirm("Replace this device copy and pending drafts with the selected backup?") { return; }
        try {
            restored: any = JSON.parse(await file.text());
            if restored.version != 1 or not restored.snapshot or not restored.snapshot.owner
                or not restored.snapshot.state or not Array.isArray(restored.pending)
                or not Array.isArray(restored.snapshot.logs) or not Array.isArray(restored.snapshot.state.history)
                or not Array.isArray(restored.snapshot.state.plan) or len(restored.snapshot.state.plan) != 7 {
                message = "This is not a supported Stride device backup."; return;
            }
            current = read_offline();
            restored.revision = current.revision if current else "";
            doc = write_offline(restored);
            message = "Backup restored on this device. Sync still requires the original account.";
        } except Exception { message = "Could not restore this backup. The previous copy has not been intentionally erased."; }
    }

    def discard(index: int) {
        if not window.confirm("Discard this unsynced draft and keep the server value?") { return; }
        try {
            doc = write_offline({**doc, "pending": doc.pending.filter(lambda (item: any, i: int) { return i != index; })});
            message = "Draft discarded. Refresh or sync to retrieve current server data.";
        } except Exception { message = "Could not update device storage. Reload before trying again."; }
    }

    working_state: any = doc.snapshot.state if doc else None;
    working_logs: any = doc.snapshot.logs if doc else [];
    working_goal: int = int(doc.snapshot["goal"]) if doc else 150;
    if doc {
        for item in doc.pending {
            if item.kind == "plan" { working_state = item.value; }
            if item.kind == "goal" { working_goal = int(item.value); }
            if item.kind == "log" {
                working_logs = working_logs.filter(lambda (row: any) { return row.date != item.key; });
                working_logs = [*working_logs, item.value];
            }
        }
    }
    summary = offline_summary(working_logs, working_goal);
    return <main className="stride-offline">
        <header><h1>Stride · Offline workspace</h1>
            <p>{"Connected to a network · server access checked when you sync" if online else "Offline · using this device only"}</p>
            <Link to="/mobile">Live dashboard / sign in</Link>
        </header>
        <p role="status" aria-live="polite">{message}</p>
        <label><input type="checkbox" checked={consent} onChange={lambda (e: any) { consent = e.target.checked; }}/>Allow an offline copy on this device. Anyone using this browser can read my saved workouts, activity and health summary.</label>
        <div className="offline-actions">
            <button disabled={busy or not online or (not doc and not consent)} onClick={save_copy}>{"Refresh device copy" if doc else "Save my account for offline use"}</button>
            {doc and <button disabled={busy or not online} onClick={sync}>Sync drafts</button>}
            {doc and <button disabled={busy} onClick={lambda { try { export_offline(doc); } except Exception { message = "Could not export a backup."; } }}>Export device backup</button>}
            {doc and <button disabled={busy} onClick={lambda {
                if window.confirm("Erase this device copy and every unsynced draft? Your server account is unchanged.") {
                    try { erase_offline(); doc = None; message = "Device copy erased."; }
                    except Exception { message = "Could not erase device storage."; }
                }
            }}>Erase device copy</button>}
            <button disabled={busy} onClick={lambda { if clear_for_logout() { jacLogout(); doc = None; message = "Logged out and device copy erased."; } }}>Log out</button>
        </div>
        <label>Restore a device backup<input type="file" accept="application/json,.json" disabled={busy} onChange={restore_backup}/></label>
        {not doc and
            <section><h2>Prepare while connected</h2><p>Sign in, finish your profile, then save a device copy here. Open this page once over HTTPS after the production app says it is ready offline. Browser storage can be cleared or evicted; keep important drafts backed up.</p></section>
        }
        {doc and <>
                <p>{"Saved for " + doc.snapshot.name + " · " + doc.snapshot.saved_at}</p>
                <p>Your device view includes local edits. They remain on this phone until you explicitly sync. The saved timestamp refers to the last server snapshot.</p>
                <section><h2>{"Pending drafts (" + str(len(doc.pending)) + ")"}</h2>
                    {doc.pending.map(lambda (item: any, i: int) { return <article key={str(i)}>
                        <strong>{item.kind + " · " + item.key}</strong>
                        <p>{("Local plan through " + item.value.end_date) if item.kind == "plan" else ((str(item.value) + " minutes per week") if item.kind == "goal" else (str(item.value.steps) + " steps · " + str(item.value.active_minutes) + " minutes · " + str(item.value.run_miles) + " miles"))}</p>
                        <button disabled={busy} onClick={lambda { discard(i); }}>Discard draft</button>
                    </article>; })}
                </section>
                <section><h2>Activity log draft</h2><p>Saving the same date replaces its daily totals after a conflict check.</p>
                    <div className="offline-fields">
                        <label>Date<input type="date" value={stamp} onChange={lambda (e: any) { stamp = e.target.value; }}/></label>
                        <label>Steps<input inputMode="numeric" value={steps} onChange={lambda (e: any) { steps = e.target.value; }}/></label>
                        <label>Active minutes<input inputMode="numeric" value={minutes} onChange={lambda (e: any) { minutes = e.target.value; }}/></label>
                        <label>Calories burned<input inputMode="numeric" value={calories} onChange={lambda (e: any) { calories = e.target.value; }}/></label>
                        <label>Miles<input inputMode="decimal" value={miles} onChange={lambda (e: any) { miles = e.target.value; }}/></label>
                    </div><button disabled={busy} onClick={save_log_draft}>Save activity draft</button>
                    <label>Weekly minutes goal<input inputMode="numeric" value={goal} onChange={lambda (e: any) { goal = e.target.value; }}/></label>
                    <button disabled={busy} onClick={lambda {
                        if goal.isdigit() and 1 <= int(goal) <= 10080 {
                            queue({"kind": "goal", "key": "goal", "base": doc.snapshot["goal"], "value": int(goal)});
                        } else { message = "Choose a goal between 1 and 10080 minutes."; }
                    }}>Save goal draft</button>
                </section>
                <section><h2>My workouts · stored on this device</h2>
                    <button disabled={busy} onClick={lambda {
                        try { queue({"kind": "plan", "key": "plan", "base": doc.snapshot.state, "value": offline_week(working_state)}); }
                        except Exception { message = "Could not generate a local week."; }
                    }}>Create next week offline</button>
                    <button onClick={lambda { try { download_plan_pdf(working_state); } except Exception { message = "Could not export the saved PDF."; } }}>Download saved plan PDF</button>
                    {working_state.plan.map(lambda (day: any) { return <article key={day.date}>
                        <h3>{day.day + " · " + day.date + " · " + day.title}</h3>
                        {day.exercises.map(lambda (exercise: any, i: int) { return <p key={str(i)}>{exercise.name + " · " + (str(exercise.duration) + " minutes" if exercise.duration else str(exercise.sets) + " × " + str(exercise.reps))}</p>; })}
                        <p>{"Saved rating: " + (working_state.feedback[str(day.index)] or "not logged")}</p>
                        {not day.rest and day.date <= today_stamp() and not working_state.feedback[str(day.index)] and <div className="offline-actions">
                            <button disabled={busy} onClick={lambda { rate(day, "easy"); }}>Too easy · draft</button>
                            <button disabled={busy} onClick={lambda { rate(day, "right"); }}>Just right · draft</button>
                            <button disabled={busy} onClick={lambda { rate(day, "hard"); }}>Too hard · draft</button>
                        </div>}
                    </article>; })}
                </section>
                <section><h2>Saved meals</h2>{doc.snapshot.meals.map(lambda (meal: any) { return <article key={meal.name}><h3>{meal.name}</h3><p>{str(meal.calories) + " kcal · " + meal.detail}</p><p>Recipe videos need a connection.</p></article>; })}</section>
                <section><h2>Activity history</h2><p>{str(summary.streak) + " active-day streak · " + str(summary.remaining) + " minutes remaining this week"}</p><p>{"Logged: " + str(summary.minutes) + " minutes this week · weekly target: " + str(working_goal) + " minutes"}</p>{working_logs.map(lambda (item: any) { return <article key={item.date}><strong>{item.date}</strong><p>{str(item.steps) + " steps · " + str(item.active_minutes) + " min · " + str(item.run_miles) + " miles · " + str(item.calories_burned) + " kcal"}</p></article>; })}</section>
                <section><h2>Archived plans</h2><details><summary>View saved history</summary>{working_state.history.map(lambda (week: any) { return <article key={week.week_id}><h3>{week.start_date + " to " + week.end_date}</h3>{week.plan.map(lambda (day: any) { return <p key={day.date}>{day.day + " · " + day.title + " · " + (week.feedback[str(day.index)] or "not logged")}</p>; })}<button onClick={lambda { download_plan_pdf(week); }}>Download this week PDF</button></article>; })}</details></section>
                <section><h2>Optional movement break</h2><label>Minutes sitting<input inputMode="numeric" value={sitting} onChange={lambda (e: any) { sitting = e.target.value; }}/></label>
                    <button onClick={lambda { show_break = sitting.isdigit() and 60 <= int(sitting) <= 1440; message = "A break is suggested at 60–1440 minutes of entered sitting time."; }}>Check break</button>
                    {show_break and <p>1 minute: stand or change position comfortably. 1 minute: gentle shoulder rolls. 1 minute: easy walking or seated ankle circles. Skip movements that feel uncomfortable.</p>}
                </section>
                <p>Sign-in, profile changes, AI Coach, videos and live Apple Health sync need a connection. Your local workouts, meals, logs, goals, history, next-week planning and PDF export do not. No automatic background syncing occurs.</p>
            </>
        }
    </main>;
}
