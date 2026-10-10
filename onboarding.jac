"""First-visit data setup dialog: data source, storage consent and app connections."""

glob HUBS: list[tuple[str, str, str]] = [
    ("apple", "Apple Health", "iPhone · steps, heart rate, workouts and sleep"),
    ("android", "Health Connect", "Android · steps, heart rate and activity"),
    ("none", "Not now", "Skip the phone health app"),
];

glob APPS: list[tuple[str, str, str]] = [
    ("oura", "Oura", "Sleep, readiness and heart rate"),
    ("fitbit", "Fitbit", "Steps, heart rate and sleep"),
    ("garmin", "Garmin Connect", "Activities, steps and heart rate"),
    ("whoop", "WHOOP", "Strain, recovery and heart rate"),
    ("strava", "Strava", "Runs, rides and workouts"),
];

def label_for(options: list[tuple[str, str, str]], key: str) -> str {
    for (option_key, name, detail) in options {
        if option_key == key { return name; }
    }
    return "";
}

"""Validate saved data choices; returns an empty dict when they are unusable."""
def:pub clean_data_prefs(raw: any) -> dict[str, any] {
    if not raw or not (raw["source"] in ["manual", "apps"]) or not (raw["store"] in [True, False]) { return {}; }
    hub = raw["hub"] if raw["hub"] in ["apple", "android", "none"] else "none";
    picked: list[str] = [];
    if Array.isArray(raw["apps"]) {
        picked = [key for (key, name, detail) in APPS if key in raw["apps"]];
    }
    if raw["source"] == "manual" { hub = "none"; picked = []; }
    return {"source": raw["source"], "store": raw["store"], "hub": hub, "apps": picked};
}

"""One-line summary of the data choices for the planning panel."""
def:pub describe_data_prefs(prefs: dict[str, any]) -> str {
    if not prefs { return ""; }
    saving = "saved on this browser" if prefs["store"] else "not stored";
    if prefs["source"] == "manual" { return "Manual entry · " + saving; }
    names = [label_for(APPS, key) for key in prefs["apps"]];
    if prefs["hub"] != "none" { names = [label_for(HUBS, prefs["hub"])] + names; }
    requested = ", ".join(names) if len(names) > 0 else "no apps chosen";
    return "App connections requested (" + requested + ") · not live yet, enter details below · " + saving;
}

def:pub DataSetup(initial: dict[str, any], onFinish: Callable[[dict[str, any]], None]) -> JsxElement {
    has step: int = 1, source: str = initial["source"] if initial else "",
        store: str = ("yes" if initial["store"] else "no") if initial else "",
        hub: str = initial["hub"] if initial else "", apps: list[str] = initial["apps"] if initial else [];

    total = 4 if source == "apps" else 2;

    def toggleApp(key: str) -> None {
        apps = [a for a in apps if a != key] if key in apps else apps + [key];
    }

    def next -> None {
        if step < total { step = step + 1; return; }
        onFinish({"source": source, "store": store == "yes", "hub": hub if source == "apps" and hub else "none", "apps": apps if source == "apps" else []});
    }

    ready = (step == 1 and source != "") or (step == 2 and store != "") or (step == 3 and hub != "") or step == 4;

    <div className="modal-backdrop">
        <div className="modal" role="dialog" aria-modal="true" aria-labelledby="setup-title">
            <div className="section-label">{"STEP " + str(step) + " OF " + str(total)}</div>
            {if step == 1 {
                <h2 id="setup-title">How should Stride get your data?</h2>
                <p className="modal-lead">Stride builds your week from your goal, experience, schedule and calorie target.</p>
                <div className="choices">
                    <button className="choice" aria-pressed={source == "manual"} onClick={lambda { source = "manual"; }}><strong>Enter it manually</strong><span>Type your details into the planning form yourself.</span></button>
                    <button className="choice" aria-pressed={source == "apps"} onClick={lambda { source = "apps"; }}><strong>Fill it from connected apps <em>Preview</em></strong><span>Use steps, heart rate and activity from health and fitness apps.</span></button>
                </div>
            } elif step == 2 {
                <h2 id="setup-title">Can Stride store your data?</h2>
                <p className="modal-lead">Saving keeps your profile, weekly plan and workout feedback on this browser so they return after a refresh. Nothing is saved to an account or the server database.</p>
                <div className="choices">
                    <button className="choice" aria-pressed={store == "yes"} onClick={lambda { store = "yes"; }}><strong>Yes, save on this browser</strong><span>You can clear saved data at any time.</span></button>
                    <button className="choice" aria-pressed={store == "no"} onClick={lambda { store = "no"; }}><strong>No, don't store my data</strong><span>Your plan lasts until you refresh or close the page. Anything saved earlier on this browser is removed.</span></button>
                </div>
            } elif step == 3 {
                <h2 id="setup-title">Connect your phone's health app</h2>
                <p className="modal-lead">Your phone's health hub gathers steps, heart rate and workouts from your devices.</p>
                <div className="choices">{for (key, name, detail) in HUBS {
                    <button key={key} className="choice" aria-pressed={hub == key} onClick={lambda { hub = key; }}><strong>{name}</strong><span>{detail}</span></button>
                }}</div>
                <p className="preview-note">Preview: this web prototype cannot read health data yet. Apple Health and Health Connect need a native phone app. Stride records your choice; enter your details manually for now.</p>
            } else {
                <h2 id="setup-title">Connect other apps</h2>
                <p className="modal-lead">Choose any other apps that track your steps, heart rate, sleep or workouts.</p>
                <div className="choices">{for (key, name, detail) in APPS {
                    <button key={key} className="choice" aria-pressed={key in apps} onClick={lambda { toggleApp(key); }}><strong>{name}</strong><span>{detail}</span></button>
                }}</div>
                <p className="preview-note">Preview: these connections are not live yet. Stride records your choices; enter your details manually for now.</p>
            }}
            <div className="modal-actions">
                {step > 1 and <button className="quiet" onClick={lambda { step = step - 1; }}>Back</button>}
                <button className="primary" disabled={not ready} onClick={next}>{"Finish setup" if step == total else "Continue"}<span>↗</span></button>
            </div>
        </div>
    </div>
}
