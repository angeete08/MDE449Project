import json;
import tempfile;
import from uuid { uuid4 }
import from datetime { date, datetime, timezone }
import from unittest.mock { patch }
import from jaclang.testing.testing { JacTestClient }
import from planner { make_state, validate_state, update_feedback, date_plan }
import from routine_rules { routine_week }
import from workout_rules { exercise_kcal, completed_indices, completed_kcal, change_completion }
import from chat_rules { rolling_chat }
import from litellm.types.utils { ModelResponse }

test "chat retention keeps Sunday and deletes the preceding week on Monday" {
    assert rolling_chat("2026-11-09", "saved", date(2026, 11, 15))["payload"] == "saved";
    assert rolling_chat("2026-11-09", "saved", date(2026, 11, 16))["payload"] == "[]";
    assert rolling_chat("2026-11-09", "saved", date(2027, 1, 4))["week"] == "2027-01-04";
}

def fixture_profile() -> dict[str, any] {
    return {"goal": "muscle", "experience": "beginner", "equipment": "bodyweight", "diet": "none", "days": 3, "calories": 2000};
}

test "completion is idempotent and partial work survives difficulty adaptation" {
    week = make_state(fixture_profile(), "2026-11-09");
    week = change_completion(week, 4, 0, True, "2026-11-14");
    again = change_completion(week, 4, 0, True, "2026-11-14");
    assert completed_indices(again, again["plan"][4]) == [0];
    assert completed_kcal(again, again["plan"][4]) == exercise_kcal(again["plan"][4]["exercises"][0]);
    adjusted = update_feedback(again, 0, "hard");
    assert adjusted["plan"][4] == again["plan"][4];
    assert len(completed_indices(adjusted, adjusted["plan"][0])) == 0;
    cleared = change_completion(adjusted, 4, 0, False, "2026-11-14");
    assert completed_kcal(cleared, cleared["plan"][4]) == 0;
    assert validate_state(adjusted)["completed"] == adjusted["completed"];
}

test "future rest and invalid exercise completions are refused" {
    state = make_state(fixture_profile(), "2026-11-09");
    for (day, exercise, today) in [(4, 0, "2026-11-10"), (1, 0, "2026-11-14"), (0, 99, "2026-11-14")] {
        rejected = False;
        try { change_completion(state, day, exercise, True, today); }
        except ValueError { rejected = True; }
        assert rejected;
    }
    state["completed"] = {"0": [-1]};
    rejected = False;
    try { validate_state(state); } except ValueError { rejected = True; }
    assert rejected;
}

test "studio routine uses confirmed weekdays focus and server validation" {
    p = fixture_profile();
    settings = {"weekdays": [1, 3, 5], "region": "core", "minutes": 20};
    state = make_state(p, "2026-11-16");
    state["routine"] = settings;
    state["plan"] = date_plan(routine_week(p, settings), "2026-11-16");
    state["completed"] = {};
    checked = validate_state(state);
    assert [d["index"] for d in checked["plan"] if not d["rest"]] == [1, 3, 5];
    assert checked["plan"][1]["exercises"][0]["name"] in ["Bird dog", "Dead bug"];
    assert all([e["sets"] == 2 for e in checked["plan"][1]["exercises"]]);
    checked["plan"][1]["exercises"][0]["name"] = "Invented exercise";
    rejected = False;
    try { validate_state(checked); } except ValueError { rejected = True; }
    assert rejected;
}

test "launch account endpoints persist completion weekly chat and future studio without duplicates" {
    with tempfile.TemporaryDirectory() as storage {
        client = JacTestClient.from_file("main.jac", base_path=storage);
        try {
            assert client.post("/function/get_chat_history", json={}).status_code == 401;
            client.register_user("launch-alice", "synthetic-launch-password");
            client.login("launch-alice", "synthetic-launch-password");
            today = date.today().isoformat();
            saved = client.post("/function/save_profile", json={"name": "Launch QA", "goal": "gain_muscle", "level": "beginner", "days_per_week": 3,
                "equipment": ["none", "dumbbells"], "diet": "none", "calorie_target": 1500, "health_conditions": "knee note",
                "store_data": True, "wearables": [], "local_date": today}).json();
            assert saved["ok"], str(saved);
            p = client.post("/function/get_profile", json={}).json()["data"]["result"];
            assert p["equipment"] == ["dumbbells"] and p["health_conditions"] == "knee note";
            assert not p["walkthrough_seen"];
            client.post("/function/finish_walkthrough", json={});
            assert client.post("/function/get_profile", json={}).json()["data"]["result"]["walkthrough_seen"];
            state = client.post("/function/get_plan_state", json={}).json()["data"]["result"];
            args = {"week_id": state["week_id"], "day": 0, "exercise": 0, "checked": True, "today": today};
            for retry in range(2) {
                response = client.post("/function/set_exercise_completed", json=args).json();
                assert response["ok"], str(response);
                assert response["data"]["result"][0]["completed"] == [0];
            }
            snap = client.post("/function/offline_snapshot", json={}).json()["data"]["result"];
            assert snap["state"]["completed"]["0"] == [0];
            altered = json.loads(json.dumps(snap["state"]));
            altered["plan"][0]["exercises"][0]["reps"] = 11;
            bad = client.post("/function/sync_offline_change", json={"owner": snap["owner"], "change": {"kind": "plan", "key": "plan", "base": snap["state"], "value": altered}}).json();
            assert not bad["ok"];
            with patch("litellm.completion", return_value=ModelResponse(choices=[{"message": {"content": "Synthetic coach answer"}, "finish_reason": "stop"}])) as model {
                with patch.dict("os.environ", {"GOOGLE_API_KEY": "synthetic-test-key", "GEMINI_API_KEY": ""}) {
                token = str(uuid4());
                for retry in range(2) {
                    history = client.post("/function/send_saved_coach", json={"question": "What does Plan do?", "request_id": token}).json();
                    assert history["ok"], str(history);
                    assert len(history["data"]["result"]["turns"]) == 1;
                }
                assert model.call_count == 1;
                }
            }
            history = client.post("/function/get_chat_history", json={}).json()["data"]["result"];
            assert history["turns"][0]["answer"] == "Synthetic coach answer";
            food_token = str(uuid4());
            client.post("/function/log_food", json={"day": today, "token": food_token, "title": "Food", "calories": 500});
            for retry in range(2) {
                reviewed = client.post("/function/review_food", json={"day": today, "token": food_token, "title": "Corrected portion", "calories": 350, "consumed": True}).json();
                assert reviewed["ok"], str(reviewed);
            }
            foods = client.post("/function/daily_food", json={"day": today}).json()["data"]["result"];
            assert len(foods) == 1 and foods[0]["calories"] == 350;
            preferences = {"goal": "general_strength", "region": "core", "experience": "beginner", "equipment": ["dumbbells"], "weekdays": [1, 3, 5], "minutes": 20, "start_date": today, "timezone": "America/Detroit"};
            preview = client.post("/function/preview_coach_routine", json={"profile": preferences}).json();
            assert preview["ok"], str(preview);
            committed = client.post("/function/save_coach_routine", json={"profile": preferences, "expected_state": preview["data"]["result"]["base"]}).json();
            assert committed["ok"], str(committed);
            after = client.post("/function/get_plan_state", json={}).json()["data"]["result"];
            assert after["plan"] == snap["state"]["plan"];
            assert after["completed"] == snap["state"]["completed"];
            assert after["upcoming"][0]["routine"]["region"] == "core";
            rejected = client.post("/function/save_coach_routine", json={"profile": preferences, "expected_state": preview["data"]["result"]["base"]}).json();
            assert not rejected["ok"];
            client.register_user("launch-bob", "synthetic-launch-password");
            client.login("launch-bob", "synthetic-launch-password");
            no_profile = client.post("/function/get_chat_history", json={}).json();
            assert not no_profile["ok"];
            client.login("launch-alice", "synthetic-launch-password");
            assert client.post("/function/delete_chat_history", json={}).json()["data"]["result"];
            assert client.post("/function/get_chat_history", json={}).json()["data"]["result"]["turns"] == [];
            assert client.post("/function/get_profile", json={}).json()["data"]["result"]["calorie_target"] == 1500;
        } finally { client.close(); }
    }
}
