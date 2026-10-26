import tempfile;
import from jaclang.testing.testing { JacTestClient }

test "account data is isolated and duplicate log replaces totals" {
    with tempfile.TemporaryDirectory() as storage {
        client = JacTestClient.from_file("main.jac", base_path=storage);
        try {
            denied = client.post("/function/get_profile", json={});
            assert denied.status_code == 401;
            denied_coach = client.post(
                "/function/ask_coach",
                json={"question": "What is in my plan?", "conversation": []}
            );
            assert denied_coach.status_code == 401;
            client.register_user("stride-test-alice", "test-password-449");
            client.login("stride-test-alice", "test-password-449");
            invalid_coach = client.post(
                "/function/ask_coach",
                json={"question": " ", "conversation": []}
            );
            assert invalid_coach.status_code >= 400;
            result = client.post(
                "/function/save_profile",
                json={
                    "name": "Alice",
                    "goal": "stay_active",
                    "level": "beginner",
                    "days_per_week": 3,
                    "equipment": ["none"],
                    "diet": "vegetarian",
                    "calorie_target": 2000,
                    "health_conditions": "",
                    "store_data": True,
                    "wearables": [],
                    "local_date": "2026-10-25"
                }
            );
            assert result.status_code == 200 , str(result.json());
            first = client.post(
                "/function/save_log",
                json={
                    "date": "2026-10-25",
                    "steps": 1000,
                    "calories_burned": 50,
                    "run_miles": 0.0,
                    "active_minutes": 10,
                    "today": "2026-10-25"
                }
            );
            assert first.status_code == 200 , str(first.json());
            second = client.post(
                "/function/save_log",
                json={
                    "date": "2026-10-25",
                    "steps": 2000,
                    "calories_burned": 80,
                    "run_miles": 0.5,
                    "active_minutes": 20,
                    "today": "2026-10-25"
                }
            );
            assert second.status_code == 200;
            summary = client.post(
                "/function/get_activity_summary", json={"today": "2026-10-25"}
            ).json();
            assert summary["data"]["result"]["weekly_minutes"] == 20 , str(summary);
            rated = client.post(
                "/function/give_feedback", json={"day_id": "0", "feedback": "too_hard"}
            );
            assert rated.status_code == 200;
            previous = client.post("/function/get_plan_state", json={}).json()["data"][
                "result"
            ];
            next_week = client.post("/function/regenerate_plan", json={});
            assert next_week.status_code == 200;
            saved = client.post("/function/get_plan_state", json={}).json()["data"][
                "result"
            ];
            assert saved["start_date"] == "2026-10-26";
            assert saved["history"][0]["plan"] == previous["plan"];
            assert saved["history"][0]["feedback"] == {"0": "hard"};
            assert saved["starting_offsets"] == previous["offsets"];
            meals = client.post("/function/meal_plan", json={}).json()["data"][
                "result"
            ];
            assert [m["name"] for m in meals] == [m["name"] for m in saved["meals"]];
            health = client.post(
                "/function/save_health_summary",
                json={"summary": {"avg_daily_steps": 6000, "avg_sleep_hours": 7.5}}
            );
            assert health.status_code == 200;
            cleared = client.post(
                "/function/save_health_summary",
                json={"summary": {"avg_daily_steps": 8000}}
            ).json()["data"]["result"];
            assert cleared["avg_sleep_hours"] is None;
            assert cleared["source"] == "Apple Health · 28-day summary";
            client.register_user("stride-test-bob", "test-password-449");
            client.login("stride-test-bob", "test-password-449");
            bob = client.post("/function/get_profile", json={}).json();
            assert bob["data"]["result"] is None , str(bob);
            logs = client.post("/function/get_logs", json={}).json();
            assert logs["data"]["result"] == [] , str(logs);
        } finally {
            client.close();
        }
    }
}
