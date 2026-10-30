import from datetime { datetime, timedelta, timezone }
import from health_sync { SYNCS, new_sync, add_batch, summarize, count_sessions, phone_base_url, start_health_sync, health_sync_status, finish_health_sync, receive_health_batch }

glob NOW: datetime = datetime(2026, 10, 15, 14, 0, tzinfo=timezone.utc);

def sample(id: str, kind: str, start: str, value: float, app: str = "iphone", zone: any = None) -> dict[str, any] {
    return {"id": id, "type": kind, "startDate": start, "endDate": start, "zoneOffset": zone, "source": {"appId": app}, "value": value};
}

test "overlapping step sources are not added together" {
    sync = new_sync(NOW, -240);
    steps = "HKQuantityTypeIdentifierStepCount";
    add_batch(sync, {"records": [
        sample("a", steps, "2026-10-13T14:00:00Z", 5000), sample("b", steps, "2026-10-13T15:00:00Z", 1000),
        sample("c", steps, "2026-10-13T14:00:00Z", 4500, "watch"), sample("d", steps, "2026-10-12T14:00:00Z", 7000),
        sample("e", steps, "2026-10-15T13:00:00Z", 300), sample("a", steps, "2026-10-13T14:00:00Z", 5000)
    ]});
    summary = summarize(sync, NOW);
    assert summary["avg_daily_steps"] == 6500;
    assert summary["days_with_steps"] == 2;
}

test "sample time zone wins over the browser offset" {
    sync = new_sync(NOW, 0);
    steps = "HKQuantityTypeIdentifierStepCount";
    add_batch(sync, {"records": [sample("a", steps, "2026-10-14T02:00:00Z", 4000, "iphone", "-05:00"), sample("b", steps, "2026-10-13T12:00:00Z", 6000)]});
    summary = summarize(sync, NOW);
    assert summary["days_with_steps"] == 1;
    assert summary["avg_daily_steps"] == 10000;
}

test "heart rate, sleep and workouts become weekly averages" {
    sync = new_sync(NOW, -240);
    rate = "HKQuantityTypeIdentifierHeartRate";
    add_batch(sync, {
        "records": [sample("h1", rate, "2026-10-12T14:00:00Z", 70), sample("h2", rate, "2026-10-12T15:00:00Z", 80), sample("h3", rate, "2026-10-12T16:00:00Z", 900)],
        "sleep": [
            {"id": "s1", "stage": "deep", "startDate": "2026-10-13T03:00:00Z", "endDate": "2026-10-13T05:00:00Z", "source": {"appId": "watch"}},
            {"id": "s2", "stage": "rem", "startDate": "2026-10-13T05:00:00Z", "endDate": "2026-10-13T10:00:00Z", "source": {"appId": "watch"}},
            {"id": "s3", "stage": "in_bed", "startDate": "2026-10-13T02:00:00Z", "endDate": "2026-10-13T11:00:00Z", "source": {"appId": "iphone"}}
        ],
        "workouts": [{"id": "w" + str(i), "startDate": "2026-10-0" + str(i + 1) + "T12:00:00Z", "endDate": "2026-10-0" + str(i + 1) + "T12:30:00Z"} for i in range(8)]
    });
    summary = summarize(sync, NOW);
    assert summary["avg_heart_rate"] == 75.0;
    assert summary["avg_sleep_hours"] == 7.0;
    assert summary["avg_workouts_per_week"] == 2.0;
}

test "missing, malformed and old samples leave fields empty" {
    sync = new_sync(NOW, 0);
    steps = "HKQuantityTypeIdentifierStepCount";
    add_batch(sync, {"records": [sample("old", steps, "2026-08-01T12:00:00Z", 9000), {"id": "bad", "type": steps, "startDate": "nope", "endDate": "nope", "value": 10}, "junk"]});
    add_batch(sync, "not a batch");
    summary = summarize(sync, NOW);
    for key in ["avg_daily_steps", "avg_heart_rate", "avg_sleep_hours", "avg_workouts_per_week"] { assert summary[key] is None; }
}

test "phone address replaces loopback hosts only" {
    assert phone_base_url("http://192.168.1.20:8000/") == "http://192.168.1.20:8000";
    assert phone_base_url("https://stride.example.edu/") == "https://stride.example.edu";
    assert phone_base_url("ftp://192.168.1.20/") == "";
    assert phone_base_url("not a url") == "";
    local = phone_base_url("http://localhost:8000/");
    assert local == "" or (local.startswith("http://") and local.endswith(":8000") and "localhost" not in local);
}

test "sync requests finish once and then refuse uploads" {
    started = start_health_sync("http://192.168.1.20:8000/", -240);
    assert started["ok"];
    assert started["link"].startswith("stridehealth://sync?host=http%3A%2F%2F192.168.1.20%3A8000&id=" + started["sync_id"]);
    receive_health_batch(started["sync_id"], {"records": [sample("a", "HKQuantityTypeIdentifierStepCount", "2026-10-12T14:00:00Z", 100)]}, "apple");
    assert health_sync_status(started["sync_id"])["state"] == "receiving";
    assert finish_health_sync(started["sync_id"])["ok"];
    status = health_sync_status(started["sync_id"]);
    assert status["state"] == "complete" and status["received"] == 1;
    assert not finish_health_sync(started["sync_id"])["ok"];
    refused = False;
    try { receive_health_batch(started["sync_id"], {}, "apple"); } except ValueError { refused = True; }
    assert refused;
    SYNCS[started["sync_id"]]["updated"] = datetime.now(timezone.utc) - timedelta(hours=1);
    assert health_sync_status(started["sync_id"])["state"] == "expired";
    assert not health_sync_status("unknown")["ok"];
}

test "overlapping workouts from two sources count once" {
    sync = new_sync(NOW, 0);
    add_batch(sync, {"workouts": [
        {"id": "watch", "startDate": "2026-10-10T12:00:00Z", "endDate": "2026-10-10T12:45:00Z"},
        {"id": "strava", "startDate": "2026-10-10T12:02:00Z", "endDate": "2026-10-10T12:44:00Z"},
        {"id": "later", "startDate": "2026-10-10T18:00:00Z", "endDate": "2026-10-10T18:30:00Z"},
        {"id": "next", "startDate": "2026-10-11T12:00:00Z", "endDate": "2026-10-11T12:30:00Z"}
    ]});
    summary = summarize(sync, NOW);
    assert summary["workouts"] == 3;
    assert summary["avg_workouts_per_week"] == 0.8;
    assert count_sessions([]) == 0;
}
