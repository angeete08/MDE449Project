import from services.offline { check_change }
import from planning_rules { generate_week, validate_profile }
import from planner { create_plan }
import from jaclang.testing.testing { JacTestClient }
import tempfile;

test "offline replay detects conflicts and acknowledges retries" {
    assert check_change("alice", "alice", None, None, {"steps": 12}) == "apply";
    assert check_change("alice", "alice", {"steps": 12}, None, {"steps": 12}) == "already_applied";
    assert check_change("alice", "alice", {"steps": 15}, None, {"steps": 12}) == "conflict";
    denied = False;
    try { check_change("bob", "alice", 150, 150, 200); }
    except ValueError { denied = True; }
    assert denied;
}

test "offline API binds snapshots to accounts and conditionally applies drafts" {
    with tempfile.TemporaryDirectory() as storage {
        client = JacTestClient.from_file("main.jac", base_path=storage);
        try {
            assert client.post("/function/offline_snapshot", json={}).status_code == 401;
            client.register_user("offline-alice", "offline-test-password");
            client.login("offline-alice", "offline-test-password");
            client.post("/function/save_profile", json={"name": "Alice", "goal": "stay_active",
                "level": "beginner", "days_per_week": 3, "equipment": ["none"], "diet": "none",
                "calorie_target": 2000, "health_conditions": "", "store_data": True,
                "wearables": [], "local_date": "2026-11-09"});
            snap = client.post("/function/offline_snapshot", json={}).json()["data"]["result"];
            change = {"kind": "goal", "key": "goal", "base": 150, "value": 180};
            result = client.post("/function/sync_offline_change", json={"owner": snap["owner"], "change": change}).json();
            assert result["data"]["result"]["status"] == "applied", str(result);
            retry = client.post("/function/sync_offline_change", json={"owner": snap["owner"], "change": change}).json();
            assert retry["data"]["result"]["status"] == "already_applied";
            client.post("/function/set_weekly_goal", json={"minutes": 200});
            conflict = client.post("/function/sync_offline_change", json={"owner": snap["owner"], "change": change}).json();
            assert conflict["data"]["result"]["status"] == "conflict";
            next_result = create_plan(snap["state"]["profile"], snap["state"]);
            plan_change = {"kind": "plan", "key": "plan", "base": snap["state"], "value": next_result["state"]};
            advanced = client.post("/function/sync_offline_change", json={"owner": snap["owner"], "change": plan_change}).json();
            assert advanced["data"]["result"]["status"] == "applied", str(advanced);
            retried_plan = client.post("/function/sync_offline_change", json={"owner": snap["owner"], "change": plan_change}).json();
            assert retried_plan["data"]["result"]["status"] == "already_applied", str(retried_plan);
            # Online calendar navigation may retain a previously created future week.
            # Offline replay must retain that week too, including its identity.
            client.post("/function/regenerate_plan", json={"today": "2026-11-09"});
            calendar_snap = client.post("/function/offline_snapshot", json={}).json()["data"]["result"];
            future_id = calendar_snap["state"]["upcoming"][0]["week_id"];
            reused = create_plan(calendar_snap["state"]["profile"], calendar_snap["state"])["state"];
            assert reused["week_id"] == future_id;
            replay = client.post("/function/sync_offline_change", json={"owner": snap["owner"], "change": {
                "kind": "plan", "key": "plan", "base": calendar_snap["state"], "value": reused
            }}).json();
            assert replay["data"]["result"]["status"] == "applied", str(replay);
            # A stale client that silently drops a saved future week must be refused.
            client.post("/function/regenerate_plan", json={"today": "2026-11-09"});
            protected = client.post("/function/offline_snapshot", json={}).json()["data"]["result"];
            broken = {key: value for (key, value) in protected["state"].items() if key != "upcoming"};
            rejected = client.post("/function/sync_offline_change", json={"owner": snap["owner"], "change": {
                "kind": "plan", "key": "plan", "base": protected["state"], "value": broken
            }}).json();
            assert not rejected["ok"], str(rejected);
            wrong = client.post("/function/sync_offline_change", json={"owner": "someone-else", "change": change}).json();
            assert not wrong["ok"];
        } finally { client.close(); }
    }
}
