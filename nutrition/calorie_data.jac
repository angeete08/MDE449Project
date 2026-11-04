"""Local USDA Foundation Foods lookup; nutrient amounts are per 100 g."""
import json;
import os;
import math;

def food_catalog() -> list[dict[str, any]] {
    with open(os.path.join(os.path.dirname(__file__), "data", "foundation_foods_2025-12-18.json"), encoding="utf-8") as source {
        foods = json.load(source)["FoundationFoods"];
    }
    catalog: list[dict[str, any]] = [];
    for food in foods {
        energy: dict[str, any] = {};
        for nutrient_id in [2048, 2047, 1008] {
            for item in food.get("foodNutrients", []) {
                nutrient = item.get("nutrient", {});
                amount = item.get("amount");
                if nutrient.get("id") == nutrient_id and str(nutrient.get("unitName", "")).lower() == "kcal" and isinstance(amount, (int, float)) and math.isfinite(amount) and amount >= 0 {
                    energy = {"kcal_per_100g": amount, "energy_basis": nutrient["name"]};
                    break;
                }
            }
            if energy { break; }
        }
        catalog.append({"id": food["fdcId"], "name": food["description"], **energy});
    }
    return catalog;
}

def:pub search_foods(query: str) -> dict[str, any] {
    if not isinstance(query, str) or len(query.strip()) < 2 or len(query) > 120 {
        return {"ok": False, "message": "Enter a food name between 2 and 120 characters.", "foods": []};
    }
    words = query.lower().split();
    matches = [food for food in food_catalog() if all(word in food["name"].lower() for word in words)];
    return {"ok": True, "foods": matches[:40], "message": "No matching food in this dataset. Try a simpler name." if not matches else ("Showing the first 40 matches. Refine your search." if len(matches) > 40 else "Choose the food that matches its preparation.")};
}

def:pub calculate_food_calories(food_id: int, grams: float) -> dict[str, any] {
    if isinstance(food_id, bool) or not isinstance(food_id, int) {
        return {"ok": False, "message": "Choose a food from the search results."};
    }
    if isinstance(grams, bool) or not isinstance(grams, (int, float)) or not math.isfinite(grams) or grams <= 0 or grams > 10000 {
        return {"ok": False, "message": "Enter a weight greater than 0 and no more than 10,000 grams."};
    }
    for food in food_catalog() {
        if food["id"] == food_id {
            if "kcal_per_100g" not in food {
                return {"ok": False, "message": "This food has no calorie value in the dataset. Choose another match."};
            }
            return {"ok": True, "food": food, "grams": grams, "calories": round(food["kcal_per_100g"] * grams / 100, 1)};
        }
    }
    return {"ok": False, "message": "Choose a food from the search results."};
}
