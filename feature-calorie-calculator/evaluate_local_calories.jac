"""Small development spot check, not a nutrition accuracy study."""
import json;
import time;
import os;
import re;
import from local_calories { estimate_local_food }
import from calorie_data { food_catalog }

with entry:__main__ {
    foods = food_catalog();
    outcomes: list[dict[str, any]] = [];
    for (query, words) in [("olive oil", ["oil", "olive"]), ("granulated sugar", ["sugars", "granulated"]), ("hummus commercial", ["hummus", "commercial"])] {
        reference: dict[str, any] = {};
        for food in foods {
            if "kcal_per_100g" in food and all(word in food["name"].lower() for word in words) and (query != "olive oil" or food["name"].lower().startswith("oil")) { reference = food; break; }
        }
        started = time.time();
        result = estimate_local_food(query, 100.0);
        outcomes.append({"query": query, "seconds": round(time.time() - started, 2), "result": result, "reference": reference});
        print(json.dumps(outcomes[-1]));
    }
    for query in ["chicken curry", "spaghetti bolognese", "cooked white rice", "butter", "raw apple", "zzzznotfood123"] {
        result = estimate_local_food(query, 100.0);
        outcomes.append({"query": query, "result": result});
        print(json.dumps(outcomes[-1]));
    }
    model_name = os.environ.get("STRIDE_LOCAL_MODEL", "qwen3:1.7b");
    model_tag = re.sub(r"[^a-zA-Z0-9.-]", "-", model_name);
    with open(os.path.join(os.path.dirname(__file__), "data", "local_model_" + model_tag + "_spot_check.json"), "w", encoding="utf-8") as output {
        json.dump({"model": model_name, "description": "Development spot check; dish quantities have no reference calorie labels. Not an independent nutrition accuracy study.", "results": outcomes}, output, indent=2);
    }
}
