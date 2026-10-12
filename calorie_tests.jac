import from .calorie_data { food_catalog, search_foods, calculate_food_calories }

test "food search matches words without case sensitivity" {
    response = search_foods("  HUMMUS commercial  ");
    assert response["ok"];
    assert len(response["foods"]) > 0;
    assert response["foods"][0]["name"] == "Hummus, commercial";
    assert not search_foods(" ")["ok"];
    assert not search_foods("a")["ok"];
    assert not search_foods("a" * 121)["ok"];
    assert search_foods("zzzznonexistentfood")["foods"] == [];
}

test "food calories scale portions and validate server inputs" {
    food = search_foods("hummus commercial")["foods"][0];
    response = calculate_food_calories(food["id"], 150);
    assert response["ok"];
    assert response["calories"] == round(food["kcal_per_100g"] * 1.5, 1);
    assert response["calories"] == 343.5;
    assert calculate_food_calories(food["id"], 100)["calories"] == round(food["kcal_per_100g"], 1);
    for weight in [0, -1, 10001, True, "100", float("nan"), float("inf")] {
        assert not calculate_food_calories(food["id"], weight as any)["ok"];
    }
    assert not calculate_food_calories(-1, 100)["ok"];
    assert not calculate_food_calories(True, 100)["ok"];
    for item in food_catalog() {
        if "kcal_per_100g" not in item {
            assert not calculate_food_calories(item["id"], 100)["ok"];
        }
    }
}
