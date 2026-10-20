"""Local single-user demo account. No external provider credentials or paid APIs.
Sessions are random capabilities held in memory; account data persists in SQLite.
This deliberately does not implement public registration or production authentication."""
import json;
import os;
import secrets;
import sqlite3;
import time;
import from planner { restore_plan, meal_catalog }

glob DEMO_DB: str = os.environ.get("STRIDE_DEMO_DB", ".jac/stride-demo.sqlite3");
glob DEMO_SESSIONS: dict[str, float] = {};

def account_db -> any {
    os.makedirs(os.path.dirname(DEMO_DB) or ".", exist_ok=True);
    db = sqlite3.connect(DEMO_DB);
    db.execute("CREATE TABLE IF NOT EXISTS account (id INTEGER PRIMARY KEY CHECK (id = 1), name TEXT NOT NULL, plan TEXT NOT NULL, health TEXT NOT NULL)");
    db.execute("INSERT OR IGNORE INTO account VALUES (1, 'Stride Demo', '{}', '{}')");
    db.commit();
    return db;
}

def require_demo(token: str) -> None {
    if DEMO_SESSIONS.get(token, 0) <= time.time() {
        DEMO_SESSIONS.pop(token, None);
        raise ValueError("Demo session expired. Open the demo account again.");
    }
}

def account_view(db: any) -> dict[str, any] {
    row = db.execute("SELECT name, plan, health FROM account WHERE id = 1").fetchone();
    return {"name": row[0], "email": "demo@stride.local", "plan": json.loads(row[1]), "health": json.loads(row[2])};
}

def:pub starter_meals -> list[dict[str, any]] {
    return meal_catalog("none")[:3];
}

def:pub open_demo_account -> dict[str, any] {
    now = time.time();
    for key in list(DEMO_SESSIONS.keys()) {
        if DEMO_SESSIONS[key] <= now { DEMO_SESSIONS.pop(key, None); }
    }
    if len(DEMO_SESSIONS) >= 50 { raise ValueError("Too many demo sessions. Try again later."); }
    token = secrets.token_hex(32);
    DEMO_SESSIONS[token] = now + 43200;
    db = account_db();
    try { return {"token": token, "account": account_view(db)}; }
    finally { db.close(); }
}

def:pub read_demo_account(token: str, poll: int = 0) -> dict[str, any] {
    require_demo(token);
    db = account_db();
    try { return account_view(db); }
    finally { db.close(); }
}

def:pub rename_demo_account(token: str, name: str) -> dict[str, any] {
    require_demo(token);
    name = name.strip();
    if not name or len(name) > 60 { raise ValueError("Use a display name between 1 and 60 characters."); }
    db = account_db();
    try {
        db.execute("UPDATE account SET name = ? WHERE id = 1", (name,));
        db.commit();
        return account_view(db);
    } finally { db.close(); }
}

def:pub save_demo_plan(token: str, plan: dict[str, any]) -> dict[str, any] {
    require_demo(token);
    result = restore_plan(plan);
    if not result["ok"] { raise ValueError(result["message"]); }
    db = account_db();
    try {
        db.execute("UPDATE account SET plan = ? WHERE id = 1", (json.dumps(result["state"]),));
        db.commit();
        return {"ok": True};
    } finally { db.close(); }
}

"""Synthetic fixture, available only through the demo session; never presented as HealthKit."""
def:pub sync_demo_health(token: str) -> dict[str, any] {
    require_demo(token);
    summary = {"avg_daily_steps": 7200, "avg_heart_rate": 72.0, "avg_sleep_hours": 7.5, "avg_workouts_per_week": 3.0,
        "source": "Synthetic server test data", "days": 28};
    db = account_db();
    try {
        db.execute("UPDATE account SET health = ? WHERE id = 1", (json.dumps(summary),));
        db.commit();
        return summary;
    } finally { db.close(); }
}

def:pub reset_demo_account(token: str) -> dict[str, any] {
    require_demo(token);
    db = account_db();
    try {
        db.execute("UPDATE account SET name = 'Stride Demo', plan = '{}', health = '{}' WHERE id = 1");
        db.commit();
        return account_view(db);
    } finally { db.close(); }
}

def:pub close_demo_account(token: str) -> dict[str, any] {
    DEMO_SESSIONS.pop(token, None);
    return {"ok": True};
}
