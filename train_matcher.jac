"""Fit and save the retrieval model entirely in Jac."""
import json;
import os;
import time;
import from calorie_data { food_catalog }
import from name_model { fit_model }

with entry:__main__ {
    folder = os.path.join(os.path.dirname(__file__), "data");
    with open(os.path.join(folder, "themealdb_recipes.json"), encoding="utf-8") as source {
        recipes = json.load(source)["recipes"];
    }
    foods = food_catalog();
    documents = [{"id": food["id"], "name": food["name"], "kind": "food"} for food in foods];
    documents += [{"id": recipe["id"], "name": recipe["name"], "kind": "recipe"} for recipe in recipes];
    model = fit_model(documents);
    model["fitted_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime());
    model["food_count"] = len(foods); model["recipe_count"] = len(recipes);
    with open(os.path.join(folder, "name_matcher.json.tmp"), "w", encoding="utf-8") as output {
        json.dump(model, output, ensure_ascii=False, separators=(",", ":"));
    }
    os.replace(os.path.join(folder, "name_matcher.json.tmp"), os.path.join(folder, "name_matcher.json"));
    print("Fitted " + str(len(documents)) + " titles; " + str(len(model["idf"])) + " learned term weights.");
}
