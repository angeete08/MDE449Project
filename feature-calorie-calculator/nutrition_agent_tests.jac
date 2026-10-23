import os;
import json;
import from unittest.mock { patch, MagicMock }
import from jaclang.byllm.lib { MockLLM, MockToolCall }
import from nutrition_agent { NutritionAgent, NutritionDecision, validate_decision, resolve_with_agent, retrieve_records, parse_decision }
import from web_nutrition { VALUE_CACHE }
import from recipe_calories { resolve_match }

def evidence() -> list[dict[str, any]] {
    return [{"id": "fixture", "name": "Cooking oil", "kcal_per_100g": 884.0, "url": "https://fdc.nal.usda.gov/food-details/1/nutrients", "portions": []}];
}

def finish_tool(final_output: str) -> str {
    return final_output;
}

test "agent validates retrieved record IDs preserves mass and requires weight assumptions" {
    decision = NutritionDecision(record_id="fixture", grams=15.0, weight_assumption="Assume 15 g of oil for this batch", explanation="Retrieved cooking oil is a proxy");
    result = validate_decision(decision, evidence(), "Oil", "");
    assert result["ok"] and result["value"] == 884 and result["grams"] == 15;
    assert result["agent"] and result["weight_assumption"];
    assert validate_decision(decision, evidence(), "Oil", "25")["grams"] == 25;
    decision.record_id = "invented";
    assert not validate_decision(decision, evidence(), "Oil", "")["ok"];
    decision.record_id = "fixture"; decision.weight_assumption = "";
    assert not validate_decision(decision, evidence(), "Oil", "")["ok"];
    decision.weight_assumption = "Assume amount";
    for invalid in [0.0, -1.0, 10001.0, float("nan"), float("inf")] {
        decision.grams = invalid;
        assert not validate_decision(decision, evidence(), "Oil", "")["ok"];
    }
    VALUE_CACHE.clear();
}

test "actual byllm typed decision runs with MockLLM and no live API" {
    decision = NutritionDecision(record_id="fixture", grams=15.0, weight_assumption="Assume one tablespoon for frying", explanation="Use retrieved oil");
    agent = NutritionAgent();
    output = {"record_id": "fixture", "grams": 15.0, "weight_assumption": decision.weight_assumption, "explanation": decision.explanation};
    mock_model = MockLLM(model_name="mockllm", config={"outputs": [MockToolCall(tool=agent.retrieve_foods, args={"query": "Cooking oil"}), MockToolCall(tool=finish_tool, args={"final_output": json.dumps(output)})]});
    with patch.dict(os.environ, {"BYLLM_DEFAULT_MODEL": "mockllm"}), patch("nutrition_agent.agent_model", mock_model), patch("nutrition_agent.retrieve_records", return_value=evidence()) {
        agent.retrieve_foods("Oil");
        actual = agent.decide("Oil", "For frying");
        result = validate_decision(parse_decision(actual), agent.evidence, "Oil", "");
        assert result["ok"] and result["grams"] == 15.0;
        assert result["weight_assumption"] == decision.weight_assumption;
        assert len(mock_model.seen_prompts) == 2;
    }
    VALUE_CACHE.clear();
}

test "broader USDA retrieval accepts only kcal energy and survives service failure" {
    response = MagicMock();
    payload = {"foods": [{"fdcId": 123, "description": "Test food", "foodNutrients": [{"nutrientId": 1008, "unitName": "kcal", "value": 222}]},
        {"fdcId": 456, "description": "Missing calories", "foodNutrients": [{"nutrientId": 1008, "unitName": "kJ", "value": 1000}]}]};
    response.__enter__.return_value.read.return_value = json.dumps(payload).encode();
    with patch.dict(os.environ, {"USDA_API_KEY": "fixture-key"}), patch("nutrition_agent.urlopen", return_value=response) {
        records = retrieve_records("zzzztestfood");
        assert len(records) == 1 and records[0]["id"] == "fdc:123" and records[0]["kcal_per_100g"] == 222;
        assert "fixture-key" not in json.dumps(records);
    }
    with patch.dict(os.environ, {"USDA_API_KEY": "fixture-key"}), patch("nutrition_agent.urlopen", side_effect=TimeoutError("fixture-key")) {
        assert retrieve_records("apple");
    }
    agent = NutritionAgent();
    with patch("nutrition_agent.retrieve_records", return_value=evidence()) as retrieve {
        for i in range(5) { agent.retrieve_foods("oil"); }
        assert retrieve.call_count == 3;
    }
}

test "recipe agent fills unknown quantities and automatically totals sourced values" {
    decision = NutritionDecision(record_id="fixture", grams=15.0, weight_assumption="Assume 15 g oil for frying", explanation="Oil estimate");
    source = validate_decision(decision, evidence(), "Oil", "");
    recipes = {"fixture": {"name": "Test recipe", "ingredients": [{"name": "Oil", "measure": "For frying"}]}};
    with patch("recipe_calories.recipe_catalog", return_value=recipes), patch("recipe_calories.google_lookup", return_value={"ok": False, "message": "No search match"}), patch("recipe_calories.resolve_with_agent", return_value=source) {
        recipe = resolve_match("recipe", "fixture", 100);
        assert recipe["rows"][0]["grams"] == "15.0";
        assert "Assume 15 g" in recipe["rows"][0]["weight_basis"];
        assert recipe["estimate"]["ok"] and recipe["estimate"]["total"] == 132.6;
    }
    with patch.dict(os.environ, {"BYLLM_DEFAULT_MODEL": ""}) {
        assert not resolve_with_agent("Oil", "For frying", "")["ok"];
    }
    VALUE_CACHE.clear();
}
