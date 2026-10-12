"""Small, explicit regression benchmark; not a user-study accuracy claim."""
import json;
import os;
import from name_model { rank_names, load_model }

with entry:__main__ {
    cases = [
        ("spagheti bolognese", "Spaghetti Bolognese"),
        ("bolognese spaghetti", "Spaghetti Bolognese"),
        ("peanut buter cookies", "Peanut Butter Cookies"),
        ("  HUMMUS  ", "Hummus"),
        ("banana pancaks", "Banana Pancakes"),
        ("salmon avocado salad", "Salmon Avocado Salad"),
        ("pancakes", "Pancakes"),
        ("chicken curry", "Chicken Curry"),
        ("hummus commercial", "Hummus, commercial")
    ];
    outcomes: list[dict[str, any]] = [];
    for (query, expected) in cases {
        matches = rank_names(query);
        actual = matches[0]["name"] if matches else "";
        outcomes.append({"query": query, "expected": expected, "actual": actual, "correct": actual == expected});
        print(query + " -> " + actual + " " + str(matches[0]["score"] if matches else 0));
    }
    for query in ["apple", "milk", "eggs", "sugar", "butter", "peanut butter", "zzzznonexistentfood"] {
        print(query + ": " + str(rank_names(query, "food", 2)));
    }
    with open(os.path.join(os.path.dirname(__file__), "data", "matching_evaluation.json"), "w") as output {
        json.dump({"scope": "Development regression examples; not independent generalization accuracy", "examples": outcomes,
            "correct": sum(int(item["correct"]) for item in outcomes), "total": len(outcomes),
            "model_fitted_at": load_model()["fitted_at"]}, output, indent=2);
    }
}
