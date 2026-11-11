"""Authentication and wire-contract checks for the integrated coach."""
import tempfile;
import from jaclang.testing.testing { JacTestClient }

test "photo coach endpoints require authentication and accept valid account requests" {
    with tempfile.TemporaryDirectory() as storage {
        client = JacTestClient.from_file("main.jac", base_path=storage);
        try {
            calls: list[tuple[str, dict[str, any]]] = [
                ("provider_info", {}),
                ("prepare_photo", {"data_url": "invalid"}),
                ("analyze_photo", {"data_url": "invalid", "consent_id": "unused"}),
                ("refine_goal", {"message": "", "previous": {"style": "muscle", "upper": 3, "lower": 0}, "consent_id": "unused"}),
                ("validate_profile", {"profile": {"start_date": "2026-11-11"}})
            ];
            for (name, payload) in calls {
                denied = client.post("/function/" + name, json=payload);
                assert denied.status_code == 401, name + ": " + str(denied.status_code);
            }
            client.register_user("coach-migration-test", "test-password-449");
            client.login("coach-migration-test", "test-password-449");
            info = client.post("/function/provider_info", json={});
            assert info.status_code == 200;
            assert "key" not in str(info.json()["data"]["result"]).lower();
            photo = client.post("/function/prepare_photo", json={"data_url": "invalid"});
            assert photo.status_code == 200 and not photo.json()["data"]["result"]["valid"];
            observation = client.post("/function/analyze_photo", json={"data_url": "invalid", "consent_id": "unused"});
            assert observation.status_code == 200 and observation.json()["data"]["result"]["status"] == "invalid";
            profile = client.post("/function/validate_profile", json={"profile": {"start_date": "2026-11-11"}});
            assert profile.status_code == 200 and profile.json()["data"]["result"]["valid"];
        } finally { client.close(); }
    }
}
