import from services.nutrition { clean_analysis }
import unittest;

test "nutrition estimates require a complete food result and bounded numeric scales" {
    row = {
        "food": True,
        "title": " Rice bowl ",
        "description": "Rice with tofu.",
        "processing": "Mixed",
        "protein": "Tofu",
        "fat": "Unclear",
        "fiber": "Some",
        "level": 3,
        "calories": 450
    };
    assert clean_analysis(row)["title"] == "Rice bowl";
    for (field, bad) in [
        ("level", 6),
        ("calories", -1),
        ("food", False),
        ("fiber", "")
    ] {
        with unittest.TestCase().assertRaises(ValueError) {
            clean_analysis({** row, field: bad});
        }
    }
}
