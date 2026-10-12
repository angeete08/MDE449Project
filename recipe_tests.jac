import math;
import from name_model { rank_names, normalize_name, load_model }
import from recipe_calories { measured_grams, match_calories, resolve_match, estimate_recipe, suggest_ingredient, recipe_catalog }
import from calorie_data { food_catalog }

test "fitted model handles typos word order and singular ingredient names" {
    assert load_model()["recipe_count"] >= 700;
    for query in ["spagheti bolognese", "bolognese spaghetti"] {
        assert rank_names(query)[0]["name"] == "Spaghetti Bolognese";
    }
    assert rank_names("peanut buter cookies")[0]["name"] == "Peanut Butter Cookies";
    assert rank_names("banana pancaks")[0]["name"] == "Banana Pancakes";
    assert suggest_ingredient("sugar")[0]["name"] == "Sugars, granulated";
    assert "Apples," in suggest_ingredient("apple")[0]["name"];
    assert "whole" in suggest_ingredient("eggs")[0]["name"];
    assert not rank_names("zzzznonexistentfood");
    assert suggest_ingredient("salt") == [];
}

test "single action food calories and recipe proxy are distinct" {
    food = match_calories("hummus commercial", 150);
    assert food["ok"] and food["kind"] == "food";
    assert food["calories"] == 343.5;
    recipe = match_calories("Hummus", 150);
    assert recipe["ok"] and recipe["kind"] == "recipe";
    assert recipe["proxy"]["calories"] == 343.5;
    dish = match_calories("spagheti bolognese", 150);
    assert dish["kind"] == "recipe";
    assert not dish["proxy"];
    assert "calories" not in dish;
    assert not match_calories("zzzznonexistentfood", 100)["ok"];
    assert not match_calories(" ", 100)["ok"];
    assert not match_calories("hummus", -1)["ok"];
    assert not resolve_match("recipe", "invalid", 100)["ok"];
}

test "only explicit mass units prefill gram weights" {
    assert measured_grams("100g ") == "100.0";
    assert measured_grams("1.25kg") == "1250.0";
    assert measured_grams("2 oz") == "56.7";
    for measure in ["1 cup", "2 eggs", "300ml", "to taste", "1/2", "400g can", ""] {
        assert measured_grams(measure) == "";
    }
}

test "recipe totals use validated ingredient weights and servings" {
    recipe = resolve_match("recipe", "52958", 100);
    assert recipe["ok"];
    assert len(recipe["rows"]) == 3;
    weights = [250.0, 100.0, 50.0];
    rows = [{"food_id": int(row["food_id"]), "grams": weights[i]} for (i, row) in enumerate(recipe["rows"])];
    foods = {food["id"]: food for food in food_catalog()};
    expected = sum(foods[row["food_id"]]["kcal_per_100g"] * row["grams"] / 100 for row in rows);
    estimate = estimate_recipe("52958", rows, 10);
    assert estimate["ok"];
    assert estimate["total"] == round(expected, 1);
    assert estimate["per_serving"] == round(expected / 10, 1);
    assert len(estimate["breakdown"]) == 3;
    assert not estimate_recipe("52958", rows[:2], 10)["ok"];
    for servings in [0, -1, 101, True, 1.5] {
        assert not estimate_recipe("52958", rows, servings as any)["ok"];
    }
    for invalid in [0, -1, True, "100", float("nan"), float("inf"), 10001] {
        changed = [{**row, "grams": invalid} for row in rows];
        assert not estimate_recipe("52958", changed, 10)["ok"];
    }
    assert not estimate_recipe("52958", [{"food_id": -1, "grams": 10} for row in rows], 10)["ok"];
    manual = [{"food_id": 0, "grams": 100, "manual_kcal": 200} for row in rows];
    assert estimate_recipe("52958", manual, 3)["per_serving"] == 200;
    for invalid in [-1, 1001, True, float("nan"), float("inf")] {
        assert not estimate_recipe("52958", [{**row, "manual_kcal": invalid} for row in manual], 3)["ok"];
    }
}
