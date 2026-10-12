"""Name retrieval and USDA-backed ingredient estimates. No invented nutrition labels."""
import json;
import os;
import re;
import math;
import from calorie_data { food_catalog, calculate_food_calories }
import from name_model { rank_names, normalize_name }

glob RECIPE_CACHE: dict[str, any] = {};

def recipe_catalog() -> dict[str, any] {
    if not RECIPE_CACHE {
        with open(os.path.join(os.path.dirname(__file__), "data", "themealdb_recipes.json"), encoding="utf-8") as source {
            for recipe in json.load(source)["recipes"] { RECIPE_CACHE[recipe["id"]] = recipe; }
        }
    }
    return RECIPE_CACHE;
}

def measured_grams(measure: str) -> str {
    found = re.fullmatch(r"\s*(\d+(?:\.\d+)?)\s*(g|grams?|kg|kilograms?|oz|ounces?|lb|lbs|pounds?)\s*", measure.lower());
    if not found { return ""; }
    amount = float(found.group(1));
    unit = found.group(2);
    factor = 1.0;
    if unit.startswith("k") { factor = 1000.0; }
    elif unit.startswith("o") { factor = 28.349523125; }
    elif unit.startswith("l") or unit.startswith("p") { factor = 453.59237; }
    return str(round(amount * factor, 1));
}

def:pub suggest_ingredient(query: str) -> list[dict[str, any]] {
    if not isinstance(query, str) or len(query.strip()) < 2 or len(query) > 120 { return []; }
    available = {food["id"] for food in food_catalog() if "kcal_per_100g" in food};
    candidates = rank_names(query, "food", 20);
    floor = max(0.4, candidates[0]["score"] - 0.18) if candidates else 1.0;
    return [candidate for candidate in candidates if candidate["id"] in available and candidate["score"] >= floor][:5];
}

def:pub resolve_match(kind: str, match_id: str, grams: float) -> dict[str, any] {
    if isinstance(grams, bool) or not isinstance(grams, (int, float)) or not math.isfinite(grams) or grams <= 0 or grams > 10000 {
        return {"ok": False, "message": "Enter a portion greater than 0 and no more than 10,000 grams."};
    }
    if kind == "food" {
        if not isinstance(match_id, str) or not match_id.isdigit() {
            return {"ok": False, "message": "Food match not found."};
        }
        result = calculate_food_calories(int(match_id), grams);
        if result["ok"] { result["kind"] = "food"; result["name"] = result["food"]["name"]; }
        return result;
    }
    if kind != "recipe" or match_id not in recipe_catalog() {
        return {"ok": False, "message": "Recipe match not found."};
    }
    recipe = recipe_catalog()[match_id];
    rows: list[dict[str, any]] = [];
    for ingredient in recipe["ingredients"] {
        candidates = suggest_ingredient(ingredient["name"]);
        rows.append({"name": ingredient["name"], "measure": ingredient["measure"], "grams": measured_grams(ingredient["measure"]),
            "food_id": str(candidates[0]["id"]) if candidates else "", "candidates": candidates, "manual_kcal": ""});
    }
    result = {"ok": True, "kind": "recipe", "name": recipe["name"], "id": match_id, "rows": rows,
        "url": "https://www.themealdb.com/meal/" + match_id, "proxy": {}};
    # A similarly named ingredient is NOT a calorie label for a whole dish.
    # Only an exact base-name food (e.g. Hummus, commercial) can be a proxy.
    for food in food_catalog() {
        if normalize_name(food["name"].split(",")[0]) == normalize_name(recipe["name"]) and "kcal_per_100g" in food {
            result["proxy"] = calculate_food_calories(food["id"], grams);
            break;
        }
    }
    return result;
}

def:pub match_calories(query: str, grams: float) -> dict[str, any] {
    if not isinstance(query, str) or len(query.strip()) < 2 or len(query) > 120 {
        return {"ok": False, "message": "Enter a food or recipe name between 2 and 120 characters."};
    }
    matches = rank_names(query, limit=4);
    if not matches or matches[0]["score"] < 0.40 {
        return {"ok": False, "message": "No close match in the local dataset. Try a more specific food or recipe name."};
    }
    best = matches[0];
    result = resolve_match(best["kind"], str(best["id"]), grams);
    result["alternatives"] = matches[1:];
    result["tentative"] = best["score"] < 0.65 or (len(matches) > 1 and best["score"] - matches[1]["score"] < 0.06);
    return result;
}

def:pub estimate_recipe(recipe_id: str, rows: list[dict[str, any]], servings: int) -> dict[str, any] {
    recipes = recipe_catalog();
    if recipe_id not in recipes or not isinstance(rows, list) or len(rows) != len(recipes[recipe_id]["ingredients"]) {
        return {"ok": False, "message": "Reload the recipe before estimating its ingredients."};
    }
    if isinstance(servings, bool) or not isinstance(servings, int) or servings < 1 or servings > 100 {
        return {"ok": False, "message": "Enter a whole number of servings from 1 to 100."};
    }
    catalog = {food["id"]: food for food in food_catalog()};
    total = 0.0;
    manual_count = 0;
    breakdown: list[dict[str, any]] = [];
    for (i, row) in enumerate(rows) {
        name = recipes[recipe_id]["ingredients"][i]["name"];
        if not isinstance(row, dict) { return {"ok": False, "message": "Invalid ingredient row."}; }
        food_id = row.get("food_id"); weight = row.get("grams");
        if isinstance(weight, bool) or not isinstance(weight, (int, float)) or not math.isfinite(weight) or weight <= 0 or weight > 10000 {
            return {"ok": False, "message": "Enter a weight greater than 0 and no more than 10,000 g for " + name + "."};
        }
        manual = row.get("manual_kcal");
        if manual is not None {
            if isinstance(manual, bool) or not isinstance(manual, (int, float)) or not math.isfinite(manual) or manual < 0 or manual > 1000 {
                return {"ok": False, "message": "Enter a calorie value from 0 to 1,000 kcal per 100 g for " + name + "."};
            }
            food = {"name": name + " (user-entered label)", "kcal_per_100g": manual};
            food_id = None; manual_count += 1;
        } else {
            if isinstance(food_id, bool) or not isinstance(food_id, int) or food_id not in catalog or "kcal_per_100g" not in catalog[food_id] {
                return {"ok": False, "message": "Choose a USDA food or enter label calories for " + name + "."};
            }
            food = catalog[food_id];
        }
        kcal = food["kcal_per_100g"] * weight / 100;
        total += kcal;
        breakdown.append({"ingredient": name, "food": food["name"], "grams": weight, "calories": round(kcal, 1), "fdc_id": food_id});
    }
    return {"ok": True, "total": round(total, 1), "per_serving": round(total / servings, 1), "servings": servings, "breakdown": breakdown, "manual_count": manual_count};
}
