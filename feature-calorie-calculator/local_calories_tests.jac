import json;
import from unittest.mock { patch, MagicMock }
import from urllib.error { HTTPError }
import from local_calories { validate_local_result, estimate_local_food, LOCAL_CACHE }

def model_output() -> dict[str, any] {
    return {"recognized": True, "kcal_per_100g": 200.0, "preparation": "Typical cooked dish", "assumptions": "Assume a typical cooked recipe; ingredients and fat vary."};
}

test "local model validation rejects invalid energy and absent assumptions" {
    assert validate_local_result(model_output())["ok"];
    for invalid in [True, -1, 1001, "200", float("nan"), float("inf")] {
        assert not validate_local_result({**model_output(), "kcal_per_100g": invalid})["ok"];
    }
    assert not validate_local_result({**model_output(), "recognized": False})["ok"];
    assert not validate_local_result({**model_output(), "assumptions": ""})["ok"];
}

test "direct local estimation uses loopback JSON and scales cached energy" {
    LOCAL_CACHE.clear();
    response = MagicMock();
    response.__enter__.return_value.read.return_value = json.dumps({"done": True, "response": json.dumps(model_output())}).encode();
    with patch("local_calories.urlopen", return_value=response) as transport {
        result = estimate_local_food("chicken curry", 150.0);
        assert result["ok"] and result["calories"] == 300.0;
        assert result["local_model"] and "web_source" not in result;
        request = transport.call_args.args[0];
        assert request.full_url == "http://127.0.0.1:11434/api/generate";
        payload = json.loads(request.data);
        assert payload["stream"] is False and payload["format"]["type"] == "object";
        assert estimate_local_food("chicken curry", 50.0)["calories"] == 100.0;
        assert transport.call_count == 1;
    }
    LOCAL_CACHE.clear();
}

test "invalid input and unavailable local service never produce calories" {
    LOCAL_CACHE.clear();
    with patch("local_calories.urlopen", side_effect=TimeoutError("Unavailable")) as transport {
        assert not estimate_local_food("x", 100.0)["ok"];
        assert not estimate_local_food("apple", -1.0)["ok"];
        assert transport.call_count == 0;
        result = estimate_local_food("apple", 100.0);
        assert not result["ok"] and "No online search was used" in result["message"];
        assert "calories" not in result;
    }
}

test "MLX schema limitation retries JSON text and still validates values" {
    LOCAL_CACHE.clear();
    response = MagicMock();
    response.__enter__.return_value.read.return_value = json.dumps({"done": True, "response": json.dumps(model_output())}).encode();
    error = HTTPError("http://127.0.0.1:11434/api/generate", 501, "Grammar unavailable", None, None);
    with patch("local_calories.urlopen", side_effect=[error, response]) as transport {
        result = estimate_local_food("banana", 100.0);
        assert result["ok"] and result["calories"] == 200.0;
        assert transport.call_count == 2;
        payload = json.loads(transport.call_args.args[0].data);
        assert "format" not in payload;
        assert "ONLY with a JSON object" in payload["system"];
    }
    LOCAL_CACHE.clear();
}
