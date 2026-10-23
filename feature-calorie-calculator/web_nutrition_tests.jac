import os;
import time;
import json;
import from unittest.mock { patch, MagicMock }
import from web_nutrition { parse_search, google_lookup, web_calorie_record, SEARCH_CACHE, VALUE_CACHE, REQUEST_TIMES }
import from recipe_calories { match_calories, resolve_match, estimate_recipe }

def default_lookup(name: str, measure: str, kind: str) -> dict[str, any] {
    source = {"ok": True, "value": 123.0 if kind == "calories" else 80.0, "url": "https://example.org/food", "title": name, "kind": kind, "lookup_id": kind + name};
    VALUE_CACHE[kind + name] = {**source, "name": name, "time": time.time()};
    return source;
}

test "web values outrank local matches and recipe totals calculate on load" {
    recipe_fixture = {"fixture": {"name": "Test batch", "ingredients": [{"name": "Apple", "measure": "100g"}, {"name": "Egg", "measure": "2"}]}};
    with patch("recipe_calories.google_lookup", side_effect=default_lookup), patch("recipe_calories.recipe_catalog", return_value=recipe_fixture) {
        recipe = resolve_match("recipe", "fixture", 100);
        assert recipe["rows"][0]["grams"] == "100.0";
        assert not recipe["rows"][0]["weight_source"];
        assert recipe["rows"][1]["grams"] == "80.0";
        assert all(row["food_id"] == "" and row["calorie_source"] for row in recipe["rows"]);
        assert recipe["estimate"]["ok"];
        assert recipe["estimate"]["web_count"] == 2;
        assert recipe["estimate"]["total"] == 221.4;
        assert recipe["estimate"]["manual_count"] == 0;
        food = match_calories("hummus commercial", 100);
        assert food["web_source"] and food["calories"] == 123.0;
    }
    with patch("recipe_calories.google_lookup", return_value={"ok": False, "message": "Offline"}), patch("recipe_calories.recipe_catalog", return_value=recipe_fixture) {
        recipe = resolve_match("recipe", "fixture", 100);
        assert recipe["estimate"]["ok"] and recipe["estimate"]["web_count"] == 0;
        assert recipe["rows"][1]["grams"] == "100.0";
    }
    VALUE_CACHE.clear();
}

def snippet(name: str, text: str, url: str = "https://example.org/nutrition") -> dict[str, any] {
    return {"organic_results": [{"title": name, "snippet": text, "link": url}]};
}

test "web parser requires matching food explicit units quantity and safe source" {
    calories = parse_search(snippet("Canned chickpeas", "120 kcal per 100 g"), "canned chickpeas", "", "calories");
    assert calories["ok"] and calories["value"] == 120;
    assert parse_search(snippet("Salt", "100 grams contains 0 calories"), "salt", "", "calories")["value"] == 0;
    weight = parse_search(snippet("Chickpeas", "1 can chickpeas weighs 400 grams"), "chickpeas", "1 can", "weight");
    assert weight["ok"] and weight["value"] == 400;
    assert not parse_search(snippet("Chickpeas", "2 cans chickpeas weighs 800 grams"), "chickpeas", "1 can", "weight")["ok"];
    assert not parse_search(snippet("Butter", "120 kcal per 100 g"), "chickpeas", "", "calories")["ok"];
    assert not parse_search(snippet("Chickpeas", "120 kcal per serving"), "chickpeas", "", "calories")["ok"];
    for invalid in ["-120 kcal per 100 g", "1,200 kcal per 100 g", "1.2e3 kcal per 100 g"] {
        assert not parse_search(snippet("Chickpeas", invalid), "chickpeas", "", "calories")["ok"];
    }
    assert not parse_search(snippet("Chickpeas", "120 kcal per 100 g", "javascript:alert(1)"), "chickpeas", "", "calories")["ok"];
    assert not parse_search(snippet("Chickpeas", "120 kcal per 100 g and 300 kcal per 100 g"), "chickpeas", "", "calories")["ok"];
    conflicting = snippet("Chickpeas", "120 kcal per 100 g");
    conflicting["organic_results"].append({"title": "Chickpeas", "snippet": "300 kcal per 100 g", "link": "https://example.net/food"});
    assert not parse_search(conflicting, "chickpeas", "", "calories")["ok"];
}

test "google transport caches results and keeps key and failures private" {
    SEARCH_CACHE.clear(); VALUE_CACHE.clear(); REQUEST_TIMES.clear();
    response = MagicMock();
    response.__enter__.return_value.read.return_value = json.dumps(snippet("Unknown food", "200 kcal per 100 g")).encode();
    with patch.dict(os.environ, {"SERPAPI_API_KEY": "test-key"}), patch("web_nutrition.urlopen", return_value=response) as transport {
        first = google_lookup("Unknown food", "", "calories");
        second = google_lookup("Unknown food", "", "calories");
        assert first["ok"] and second["lookup_id"] == first["lookup_id"];
        assert transport.call_count == 1;
        assert "test-key" not in json.dumps(first);
        assert web_calorie_record(first["lookup_id"], "Unknown food")["value"] == 200;
        assert not web_calorie_record(first["lookup_id"], "Different food");
    }
    with patch.dict(os.environ, {"SERPAPI_API_KEY": "test-key"}), patch("web_nutrition.urlopen", side_effect=TimeoutError("test-key private URL")) {
        failed = google_lookup("Another food", "", "calories");
        assert not failed["ok"] and "test-key" not in json.dumps(failed);
    }
    with patch.dict(os.environ, {"SERPAPI_API_KEY": ""}), patch("web_nutrition.urlopen") as transport {
        assert not google_lookup("Missing food", "", "calories")["ok"];
        assert transport.call_count == 0;
    }
    SEARCH_CACHE.clear(); VALUE_CACHE.clear(); REQUEST_TIMES.clear();
}

test "online fallback fills recipe fields and uses server records in totals" {
    source = {"ok": True, "value": 100.0, "url": "https://example.org/food", "title": "Food value", "kind": "calories", "lookup_id": "fixture"};
    with patch("recipe_calories.google_lookup", return_value=source) {
        food = match_calories("zzzzmissingfood", 150);
        assert food["ok"] and food["calories"] == 150 and food["web_source"]["url"] == source["url"];
        recipe = resolve_match("recipe", "52958", 100);
    }
    name = recipe["rows"][0]["name"];
    VALUE_CACHE["fixture"] = {**source, "name": name, "time": time.time()};
    rows: list[dict[str, any]] = [{"grams": 100.0, "food_id": 0, "manual_kcal": 200.0} for row in recipe["rows"]];
    rows[0] = {"grams": 100.0, "food_id": 0, "manual_kcal": None, "web_lookup_id": "fixture"};
    result = estimate_recipe("52958", rows, 1);
    assert result["ok"] and result["web_count"] == 1 and result["manual_count"] == 2;
    assert result["total"] == 500;
    assert result["breakdown"][0]["web_source"]["url"] == source["url"];
    rows[0]["web_lookup_id"] = "forged";
    assert not estimate_recipe("52958", rows, 1)["ok"];
    VALUE_CACHE["fixture"]["time"] = time.time() - 3601;
    assert not web_calorie_record("fixture", name);
    VALUE_CACHE.clear();
}
