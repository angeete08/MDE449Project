"""Apple Health sync relay. The Stride Health iOS app uploads HealthKit samples through the
Open Wearables SDK wire format; the web app reads back four weekly averages. Requests and
samples live in server memory only and are dropped when a request expires."""
import secrets;
import socket;
import from datetime { datetime, timedelta, timezone }
import from urllib.parse { urlsplit, urlencode }
import from http { HTTPMethod }

glob SYNC_DAYS: int = 28;
glob WAIT_MINUTES: int = 15;
glob KEEP_MINUTES: int = 10;
glob MAX_OPEN: int = 50;
glob MAX_SAMPLES: int = 200000;
glob ASLEEP: list[str] = ["sleeping", "light", "deep", "rem"];
glob SYNCS: dict[str, dict[str, any]] = {};

def new_sync(now: datetime, offset_minutes: int) -> dict[str, any] {
    return {"created": now, "updated": now, "state": "waiting", "offset": offset_minutes, "expected": 0, "received": 0, "summary": {},
        "seen": set(), "steps": {}, "sleep": {}, "workouts": [], "hr_total": 0.0, "hr_count": 0};
}

def parse_time(stamp: any) -> datetime | None {
    if not isinstance(stamp, str) { return None; }
    try {
        moment = datetime.fromisoformat(stamp.replace("Z", "+00:00"));
        return moment if moment.tzinfo else moment.replace(tzinfo=timezone.utc);
    } except ValueError { return None; }
}

"""Calendar day of a sample in its recorded time zone, else the requesting browser's."""
def local_day(moment: datetime, zone: any, fallback_minutes: int) -> str {
    minutes = fallback_minutes;
    if isinstance(zone, str) and len(zone) == 6 and zone[0] in "+-" and zone[3] == ":" and zone[1:3].isdigit() and zone[4:6].isdigit() {
        minutes = (-1 if zone[0] == "-" else 1) * (int(zone[1:3]) * 60 + int(zone[4:6]));
    }
    return (moment.astimezone(timezone.utc) + timedelta(minutes=minutes)).date().isoformat();
}

def source_key(item: dict[str, any]) -> str {
    source = item.get("source");
    if not isinstance(source, dict) { return "unknown"; }
    return str(source.get("appId") or source.get("name") or "unknown") + "|" + str(source.get("deviceModel") or "");
}

def is_number(value: any) -> bool {
    return isinstance(value, (int, float)) and not isinstance(value, bool) and value == value;
}

"""Fold one SDK upload into running totals; raw samples are not kept. Returns samples accepted."""
def add_batch(sync: dict[str, any], data: any) -> int {
    if not isinstance(data, dict) { return 0; }
    since = sync["created"] - timedelta(days=SYNC_DAYS);
    added = 0;
    for (group, items) in [("records", data.get("records")), ("sleep", data.get("sleep")), ("workouts", data.get("workouts"))] {
        if not isinstance(items, list) { continue; }
        for item in items {
            if len(sync["seen"]) >= MAX_SAMPLES { return added; }
            if not isinstance(item, dict) or not isinstance(item.get("id"), str) or item["id"] in sync["seen"] { continue; }
            start = parse_time(item.get("startDate"));
            end = parse_time(item.get("endDate"));
            if start is None or end is None or end < start or start < since { continue; }
            sync["seen"].add(item["id"]);
            added += 1;
            if group == "workouts" {
                sync["workouts"].append((start, end));
            } elif group == "sleep" {
                if item.get("stage") in ASLEEP {
                    key = (local_day(end, item.get("zoneOffset"), sync["offset"]), source_key(item));
                    sync["sleep"][key] = sync["sleep"].get(key, 0.0) + (end - start).total_seconds();
                }
            } elif is_number(item.get("value")) {
                value = float(item["value"]);
                if item.get("type") == "HKQuantityTypeIdentifierStepCount" and value >= 0 {
                    key = (local_day(start, item.get("zoneOffset"), sync["offset"]), source_key(item));
                    sync["steps"][key] = sync["steps"].get(key, 0.0) + value;
                } elif item.get("type") == "HKQuantityTypeIdentifierHeartRate" and 20 <= value <= 250 {
                    sync["hr_total"] = sync["hr_total"] + value;
                    sync["hr_count"] = sync["hr_count"] + 1;
                }
            }
        }
    }
    return added;
}

"""Workouts whose times overlap (the same session saved by a Watch and an imported
app, for example) count once."""
def count_sessions(spans: list[tuple[datetime, datetime]]) -> int {
    sessions = 0;
    last_end: datetime | None = None;
    for (start, end) in sorted(spans) {
        if last_end is None or start >= last_end {
            sessions += 1;
            last_end = end;
        } elif end > last_end {
            last_end = end;
        }
    }
    return sessions;
}

"""Weekly averages for the form. Overlapping sources (iPhone and Watch) are not added
together: each day or night uses the source with the largest total. Missing data stays None."""
def summarize(sync: dict[str, any], now: datetime) -> dict[str, any] {
    today = (now + timedelta(minutes=sync["offset"])).date().isoformat();
    daily: dict[str, float] = {};
    for (key, total) in sync["steps"].items() {
        if key[0] != today { daily[key[0]] = max(daily.get(key[0], 0.0), total); }
    }
    nights: dict[str, float] = {};
    for (key, seconds) in sync["sleep"].items() { nights[key[0]] = min(max(nights.get(key[0], 0.0), seconds), 86400.0); }
    steps = min(round(sum(daily.values()) / len(daily)), 100000) if daily else None;
    heart = round(sync["hr_total"] / sync["hr_count"], 1) if sync["hr_count"] else None;
    sleep = round(sum(nights.values()) / len(nights) / 3600, 1) if nights else None;
    sessions = count_sessions(sync["workouts"]);
    workouts = min(round(sessions * 7 / SYNC_DAYS, 1), 50) if sessions else None;
    return {"avg_daily_steps": steps, "avg_heart_rate": heart, "avg_sleep_hours": sleep, "avg_workouts_per_week": workouts,
        "days": SYNC_DAYS, "days_with_steps": len(daily), "heart_rate_samples": sync["hr_count"], "nights_with_sleep": len(nights), "workouts": sessions};
}

def purge(now: datetime) {
    for sync_id in list(SYNCS.keys()) {
        sync = SYNCS[sync_id];
        limit = KEEP_MINUTES if sync["state"] == "complete" else WAIT_MINUTES;
        if now - sync["updated"] > timedelta(minutes=limit) { SYNCS.pop(sync_id, None); }
    }
}

def open_sync(sync_id: str) -> dict[str, any] | None {
    now = datetime.now(timezone.utc);
    purge(now);
    sync = SYNCS.get(sync_id);
    if sync is None or sync["state"] == "complete" { return None; }
    sync["updated"] = now;
    return sync;
}

"""This computer's LAN IPv4 address. Connecting a UDP socket sends no packets."""
def lan_address -> str {
    probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM);
    try {
        probe.connect(("192.0.2.1", 80));
        address = str(probe.getsockname()[0]);
        return "" if address.startswith("127.") else address;
    } except OSError { return ""; }
    finally { probe.close(); }
}

"""Server address the iPhone should use: the page's own address, with a loopback host
replaced by this computer's LAN address so a phone on the same Wi-Fi can reach it."""
def phone_base_url(page_url: str) -> str {
    try { parts = urlsplit(page_url); port = parts.port; }
    except ValueError { return ""; }
    if parts.scheme not in ["http", "https"] or not parts.hostname { return ""; }
    host = parts.hostname;
    if host in ["localhost", "127.0.0.1", "::1"] { host = lan_address(); }
    if not host { return ""; }
    if ":" in host { host = "[" + host + "]"; }
    return parts.scheme + "://" + host + (":" + str(port) if port else "");
}

def:pub start_health_sync(page_url: str, utc_offset_minutes: int = 0) -> dict[str, any] {
    now = datetime.now(timezone.utc);
    purge(now);
    if len(SYNCS) >= MAX_OPEN { return {"ok": False, "message": "Too many sync requests are open. Try again in a few minutes."}; }
    base = phone_base_url(page_url);
    if not base { return {"ok": False, "message": "Could not find a network address your iPhone can reach. Connect this computer to Wi-Fi and try again."}; }
    offset = utc_offset_minutes if isinstance(utc_offset_minutes, int) and -840 <= utc_offset_minutes <= 840 else 0;
    sync_id = secrets.token_hex(16);
    SYNCS[sync_id] = new_sync(now, offset);
    link = "stridehealth://sync?" + urlencode({"host": base, "id": sync_id, "days": SYNC_DAYS});
    return {"ok": True, "sync_id": sync_id, "link": link, "host": base, "expires_minutes": WAIT_MINUTES,
        "message": "Sync request ready. Open it on your iPhone with Stride Health installed."};
}

"""Polled by the web app. `poll` only varies the call so each check reaches the server."""
def:pub health_sync_status(sync_id: str, poll: int = 0) -> dict[str, any] {
    now = datetime.now(timezone.utc);
    purge(now);
    sync = SYNCS.get(sync_id);
    if sync is None { return {"ok": False, "state": "expired", "received": 0, "expected": 0, "summary": {}, "poll": poll}; }
    done = sync["state"] == "complete";
    return {"ok": True, "state": sync["state"], "received": sync["received"] if done else len(sync["seen"]), "expected": sync["expected"],
        "summary": sync["summary"] if done else {}, "poll": poll};
}

"""Called by the iOS app after the SDK finishes its initial export."""
def:pub finish_health_sync(sync_id: str) -> dict[str, any] {
    sync = open_sync(sync_id);
    if sync is None { return {"ok": False, "message": "This sync request has expired. Send a new one from Stride."}; }
    summary = summarize(sync, sync["updated"]);
    sync["state"] = "complete";
    sync["summary"] = summary;
    sync["received"] = len(sync["seen"]);
    for key in ["seen", "steps", "sleep", "workouts"] { sync[key] = type(sync[key])(); }
    return {"ok": True, "message": "Sent to Stride. Return to the web app to review the averages.", "summary": summary};
}

@restspec(method=HTTPMethod.POST, path="/api/v1/sdk/users/{user_id}/sync")
def:pub receive_health_batch(user_id: str, data: dict[str, any] | None = None, provider: str = "", sdkVersion: str = "", syncTimestamp: str = "", syncSessionId: str = "", syncType: str = "") -> dict[str, any] {
    sync = open_sync(user_id);
    if sync is None or provider != "apple" { raise ValueError("Unknown or expired sync request."); }
    sync["state"] = "receiving";
    return {"ok": True, "accepted": add_batch(sync, data)};
}

@restspec(method=HTTPMethod.POST, path="/api/v1/sdk/users/{user_id}/logs")
def:pub receive_health_log(user_id: str, events: list[dict[str, any]] | None = None, provider: str = "", sdkVersion: str = "", syncSessionId: str = "") -> dict[str, any] {
    sync = open_sync(user_id);
    if sync is None { raise ValueError("Unknown or expired sync request."); }
    for event in (events or []) {
        if isinstance(event, dict) and event.get("eventType") == "historical_data_sync_start" and isinstance(event.get("dataTypeCounts"), list) {
            sync["expected"] = sum([int(c["count"]) for c in event["dataTypeCounts"] if isinstance(c, dict) and is_number(c.get("count"))]);
        }
    }
    return {"ok": True};
}

"""The SDK reports a sign-out here; the request itself ends through finish_health_sync."""
@restspec(method=HTTPMethod.DELETE, path="/api/v1/users/{user_id}/connections/apple")
def:pub release_health_sync(user_id: str) -> dict[str, any] {
    return {"ok": True};
}
