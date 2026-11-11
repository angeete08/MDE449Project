import os;
import json;
import coach_provider;
import from http { client }
import from unittest.mock { patch, MagicMock }
import from coach_provider { _payload, _decode, _config, _info, _complete, _send }
import from coach_vision { _observation, _vision_schema, analyze_photo }
import from coach_goals { GoalDraft, _goal_reply, _balance_warning, refine_goal }
import from coach_profile { CoachProfile, validate_profile }

def _api() -> dict[str, any] {
    return {"provider": "openai", "base": "https://api.example.test/v1", "key": "TEST-ONLY", "vision": "vision-test", "text": "vision-test"};
}
def _observed() -> dict[str, any] {
    return {"human_visible": True, "regions": ["arms", "legs"], "quality": "clear", "framing": "full_body", "pose": "standing"};
}
test "API and local image payloads use their respective formats" {
    config = _api();
    body = _payload(config, "system", "prompt", _vision_schema(), "data:image/jpeg;base64,pixels");
    assert body["messages"][1]["content"][1]["image_url"]["url"] == "data:image/jpeg;base64,pixels";
    assert body["response_format"]["json_schema"]["strict"] is True;
    assert body["store"] is False and "TEST-ONLY" not in json.dumps(body);
    assert len(_payload(config, "system", "prompt", _vision_schema())["messages"][1]["content"]) == 1;
    config["provider"] = "ollama";
    local = _payload(config, "system", "prompt", _vision_schema(), "data:image/jpeg;base64,pixels");
    assert local["messages"][1]["images"] == ["pixels"];
    assert local["stream"] is False;
}
test "HTTPS transport preserves base path authenticates and closes" {
    connection: any = MagicMock();
    connection.getresponse.return_value.status = 200;
    connection.getresponse.return_value.read.return_value = b'{"ok":true}';
    with patch.object(client, "HTTPSConnection", return_value=connection) {
        assert _send("https://api.example.test/v1", "/chat/completions", {}, "TEST-ONLY")["ok"];
    }
    assert connection.request.call_args.args[1] == "/v1/chat/completions";
    assert connection.request.call_args.kwargs["headers"]["Authorization"] == "Bearer TEST-ONLY";
    connection.close.assert_called_once();
}
test "transport rejects redirects errors and oversized responses" {
    for status in [302, 401, 429, 500, 200] {
        connection: any = MagicMock();
        connection.getresponse.return_value.status = status;
        connection.getresponse.return_value.read.return_value = b"x" * 1048577;
        failed = False;
        with patch.object(client, "HTTPSConnection", return_value=connection) {
            try { _send("https://api.example.test/v1", "/chat/completions", {}); }
            except ValueError { failed = True; }
        }
        assert failed;
        connection.close.assert_called_once();
    }
}
test "both providers decode to the same strict observation" {
    content = json.dumps(_observed());
    local = _decode("ollama", {"done": True, "message": {"content": content}});
    remote = _decode("openai", {"choices": [{"finish_reason": "stop", "message": {"content": content}}]});
    assert _observation(local).regions == _observation(remote).regions;
    for response in [
        {"choices": [{"finish_reason": "length", "message": {"content": content}}]},
        {"choices": [{"finish_reason": "stop", "message": {"refusal": "no", "content": content}}]},
        {"choices": [{"finish_reason": "stop", "message": {"content": "not json"}}]}
    ] {
        failed = False;
        try { _decode("openai", response); } except ValueError { failed = True; }
        assert failed;
    }
}
test "changed destination blocks transmission and configured API completes" {
    config = _api();
    response = {"choices": [{"finish_reason": "stop", "message": {"content": json.dumps(_observed())}}]};
    with patch.object(coach_provider, "_config", return_value=config), patch.object(coach_provider, "_send", return_value=response) as send {
        failed = False;
        try { _complete("system", "prompt", _vision_schema(), "old-destination"); } except ValueError { failed = True; }
        assert failed;
        send.assert_not_called();
        assert _complete("system", "prompt", _vision_schema(), _info(config).consent_id) == _observed();
        assert send.call_args.args[1] == "/chat/completions";
    }
}
test "text-only local model is rejected before image transmission" {
    config = _api(); config["provider"] = "ollama";
    with patch.object(coach_provider, "_config", return_value=config), patch.object(coach_provider, "_send", return_value={"capabilities": ["completion"]}) as send {
        failed = False;
        try { _complete("system", "prompt", _vision_schema(), _info(config).consent_id, "data:image/jpeg;base64,pixels"); } except ValueError { failed = True; }
        assert failed and send.call_count == 1;
        assert send.call_args.args[1] == "/api/show";
    }
}
test "API configuration requires HTTPS and server credentials" {
    for base in ["http://api.example.test/v1", "https://user:pass@api.example.test/v1", "https://api.example.test/v1?secret=x"] {
        with patch.dict(os.environ, {"COACH_PROVIDER": "openai", "COACH_API_BASE": base, "COACH_API_KEY": "TEST-ONLY", "COACH_API_MODEL": "test"}) {
            failed = False;
            try { _config(); } except ValueError { failed = True; }
            assert failed;
        }
    }
    with patch.dict(os.environ, {"COACH_PROVIDER": "openai", "COACH_API_KEY": "", "COACH_API_MODEL": ""}) {
        failed = False;
        try { _config(); } except ValueError { failed = True; }
        assert failed;
    }
    assert _info(_api()).destination == "api.example.test";
}
test "vision abstains and rejects unexpected or diagnostic output" {
    assert _observation({"human_visible": False, "regions": [], "quality": "unusable", "framing": "unclear", "pose": "unclear"}).status == "uncertain";
    for regions in [["face"], ["arms", "arms"], [3]] {
        data = _observed(); data["regions"] = regions;
        failed = False;
        try { _observation(data); } except ValueError { failed = True; }
        assert failed;
    }
    data = _observed(); data["body_fat"] = 20;
    failed = False;
    try { _observation(data); } except ValueError { failed = True; }
    assert failed;
    assert analyze_photo("not an image", "unused").status == "invalid";
}
test "goal refinement exposes balance reminder without medical inference" {
    result = _goal_reply({"style": "muscle", "upper": 3, "lower": 0, "needs_detail": False});
    assert result.status == "ready" and "not a medical risk score" in result.warning;
    assert not _balance_warning(2, 1);
    assert _balance_warning(0, 3);
    assert _goal_reply({"style": "muscle", "upper": 1, "lower": 1, "needs_detail": True}).status == "clarify";
    assert refine_goal("", GoalDraft(), "unused").status == "invalid";
}
test "custom goal and self-reported baseline are server validated" {
    assert not validate_profile(CoachProfile(goal="other", start_date="2026-11-11")).valid;
    profile = CoachProfile(goal="other", custom_goal="Arm strength", upper_emphasis=3, lower_emphasis=0, activity_days=2, start_date="2026-11-11");
    result = validate_profile(profile);
    assert result.valid and result.warning and "2" in result.baseline;
    profile.activity_days = 8;
    assert not validate_profile(profile).valid;
    profile.activity_days = 2; profile.upper_emphasis = 4;
    assert not validate_profile(profile).valid;
}
