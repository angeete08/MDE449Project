"""Refresh public educational recipe data. Run explicitly; never during a search."""
import json;
import os;
import string;
import time;
import from urllib.request { urlopen }

with entry:__main__ {
    meals: dict[str, any] = {};
    for letter in string.ascii_lowercase {
        with urlopen("https://www.themealdb.com/api/json/v1/1/search.php?f=" + letter, timeout=15) as response {
            payload = json.loads(response.read());
        }
        for meal in payload.get("meals") or [] {
            # Only keep the facts used by matching and ingredient calculations.
            ingredients = [{"name": str(meal.get("strIngredient" + str(i)) or "").strip(),
                "measure": str(meal.get("strMeasure" + str(i)) or "").strip()} for i in range(1, 21)
                if str(meal.get("strIngredient" + str(i)) or "").strip()];
            meals[meal["idMeal"]] = {"id": meal["idMeal"], "name": meal["strMeal"], "ingredients": ingredients};
        }
        print(letter + ": " + str(len(meals)) + " recipes", flush=True);
        time.sleep(0.3);
    }
    path = os.path.join(os.path.dirname(__file__), "data", "themealdb_recipes.json");
    with open(path + ".tmp", "w", encoding="utf-8") as output {
        json.dump({"source": "https://www.themealdb.com/api.php", "retrieved": time.strftime("%Y-%m-%d", time.gmtime()),
            "recipes": list(meals.values())}, output, ensure_ascii=False, indent=2);
    }
    os.replace(path + ".tmp", path);
    print("Saved " + str(len(meals)) + " recipes. Run train_matcher.jac next.");
}
