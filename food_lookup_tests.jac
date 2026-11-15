import from services.food_lookup { lookup_food, food_table, match_score }

test "offline table keeps only foods with calorie values" {
    table = food_table();
    assert len(table) == 323;
    assert all([row["kcal_per_100g"] >= 0 for row in table]);
    hummus = [row for row in table if row["name"] == "Hummus, commercial"];
    assert len(hummus) == 1 and hummus[0]["kcal_per_100g"] == 229.0;
}

test "lookup finds USDA foods with typos and plurals" {
    hummus = [row["name"] for row in lookup_food("humus")[:2]];
    assert "Hummus, commercial" in hummus;
    assert lookup_food("bananas")[0]["name"].startswith("Bananas");
    assert lookup_food("brocoli")[0]["name"] == "Broccoli, raw";
    assert lookup_food("milk")[0]["name"].startswith("Milk,");
    assert lookup_food("egg")[0]["name"].startswith("Egg,");
    assert all(["almond" not in row["name"].lower() for row in lookup_food("salmon")]);
}

test "lookup includes Stride meal ideas with per-serving calories" {
    tacos = lookup_food("bean tacos");
    assert tacos[0]["kind"] == "meal" and tacos[0]["calories"] == 510;
    assert tacos[0]["source"] == "Stride meal idea, per serving";
}

test "lookup rejects bad queries and returns nothing for nonsense" {
    for bad in ["", " x ", "y" * 81] {
        rejected = False;
        try { lookup_food(bad); } except ValueError { rejected = True; }
        assert rejected;
    }
    assert lookup_food("zzqxv") == [];
    assert match_score("", "Banana") == 0.0;
}
