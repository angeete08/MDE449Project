"""Build data/usda_foods.json, the offline food table, from a USDA FoodData Central
Foundation Foods JSON export (public domain). Keeps only names and kcal per 100 g,
using Atwater specific energy (2048), then general energy (2047), then energy (1008).

    jac run --no-serve --no-takeover tools/build_offline_foods.jac <foundation_foods.json>

The October 2026 table came from foundation_foods_2025-12-18.json on the
feature/calorie-calculator branch."""
import json;
import math;
import sys;

def kcal_per_100g(food: dict[str, any]) -> float | None {
    for nutrient_id in [2048, 2047, 1008] {
        for item in food.get("foodNutrients", []) {
            nutrient = item.get("nutrient", {});
            amount = item.get("amount");
            if nutrient.get("id") == nutrient_id and str(nutrient.get("unitName", "")).lower() == "kcal"
                and isinstance(amount, (int, float)) and math.isfinite(amount) and amount >= 0 {
                return round(float(amount), 1);
            }
        }
    }
    return None;
}

def sort_key(row: dict[str, any]) -> str {
    return str(row["name"]).lower();
}

with entry:__main__ {
    with open(sys.argv[-1], encoding="utf-8") as source { foods = json.load(source)["FoundationFoods"]; }
    table: list[dict[str, any]] = [];
    for food in foods {
        kcal = kcal_per_100g(food);
        if kcal is not None { table.append({"id": food["fdcId"], "name": food["description"], "kcal_per_100g": kcal}); }
    }
    table = sorted(table, key=sort_key);
    with open("data/usda_foods.json", "w", encoding="utf-8") as out {
        json.dump({"source": "USDA FoodData Central Foundation Foods, 2025-12-18 release", "foods": table}, out, indent=0, ensure_ascii=False);
        out.write("\n");
    }
    print("Wrote " + str(len(table)) + " of " + str(len(foods)) + " foods with calorie values.");
}
