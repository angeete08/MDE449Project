import accounts;
import tempfile;
import time;
import from planner { make_state, update_feedback }

test "demo account lifecycle and server persistence" {
    original = accounts.DEMO_DB;
    with tempfile.TemporaryDirectory() as folder {
        accounts.DEMO_DB = folder + "/demo.sqlite3";
        try {
            opened = accounts.open_demo_account();
            token = opened["token"];
            assert opened["account"]["plan"] == {};
            assert len(accounts.starter_meals()) == 3;
            assert accounts.rename_demo_account(token, "  Alex  ")["name"] == "Alex";
            summary = accounts.sync_demo_health(token);
            assert summary["source"] == "Synthetic server test data";
            assert summary["avg_daily_steps"] == 7200;
            state = make_state({"goal": "muscle", "days": 3, "equipment": "bodyweight", "diet": "none", "experience": "beginner", "calories": 2100});
            state = update_feedback(state, 0, "hard");
            assert accounts.save_demo_plan(token, state)["ok"];
            accounts.close_demo_account(token);
            fresh = accounts.open_demo_account();
            saved = fresh["account"];
            assert saved["name"] == "Alex";
            assert saved["plan"]["feedback"] == state["feedback"];
            assert saved["plan"]["plan"][0] == state["plan"][0];
            assert saved["health"] == summary;
            cleared = accounts.reset_demo_account(fresh["token"]);
            assert cleared["plan"] == {} and cleared["health"] == {};
            assert cleared["name"] == "Stride Demo";
            accounts.close_demo_account(fresh["token"]);
        } finally { accounts.DEMO_DB = original; }
    }
}

test "demo session authorization and input validation" {
    original = accounts.DEMO_DB;
    with tempfile.TemporaryDirectory() as folder {
        accounts.DEMO_DB = folder + "/demo.sqlite3";
        try {
            token = accounts.open_demo_account()["token"];
            for name in ["", "   ", "x" * 61] {
                rejected = False;
                try { accounts.rename_demo_account(token, name); }
                except ValueError { rejected = True; }
                assert rejected;
            }
            rejected = False;
            try { accounts.save_demo_plan(token, {"invalid": True}); }
            except ValueError { rejected = True; }
            assert rejected;
            accounts.DEMO_SESSIONS[token] = time.time() - 1;
            for invalid in ["made-up", token] {
                rejected = False;
                try { accounts.read_demo_account(invalid); }
                except ValueError { rejected = True; }
                assert rejected;
            }
            token = accounts.open_demo_account()["token"];
            accounts.close_demo_account(token);
            rejected = False;
            try { accounts.sync_demo_health(token); }
            except ValueError { rejected = True; }
            assert rejected;
        } finally { accounts.DEMO_DB = original; }
    }
}
