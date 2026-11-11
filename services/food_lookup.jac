"""Offline calorie lookup, the fallback when meal photo analysis is unavailable.
Matches bundled USDA Foundation Foods (kcal per 100 g) and Stride's own meal ideas
(kcal per serving). Needs no internet connection or API key."""
import json;
import os;
import re;
import from difflib { SequenceMatcher }
import from planner { meal_catalog }

glob FOODS: list[dict[str, any]] = [];

def food_table -> list[dict[str, any]] {
    if not FOODS {
        root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)));
        with open(os.path.join(root_dir, "data", "usda_foods.json"), encoding="utf-8") as source {
            FOODS.extend(json.load(source)["foods"]);
        }
    }
    return FOODS;
}

def meal_table -> list[dict[str, any]] {
    meals: dict[str, dict[str, any]] = {};
    for diet in ["none", "vegetarian", "keto", "protein"] {
        for meal in meal_catalog(diet) { meals[meal["name"].lower()] = meal; }
    }
    return list(meals.values());
}

def words(text: str) -> list[str] {
    found: list[str] = [];
    for word in re.findall(r"[a-z0-9]+", text.lower()) {
        found.append(word[:-1] if len(word) > 3 and word.endswith("s") and not word.endswith("ss") else word);
    }
    return found;
}

"""How well one query word appears in a name: exact, a prefix of a longer word, or a
close spelling. Short words must match exactly, so "egg" does not find "eggplant"."""
def word_credit(word: str, have: list[str]) -> float {
    best = 0.0;
    for w in have {
        if w == word { return 1.0; }
        if len(word) >= 4 and w.startswith(word) {
            best = max(best, 0.9);
        } elif len(word) >= 4 {
            close = SequenceMatcher(None, word, w).ratio();
            if close >= 0.85 { best = max(best, 0.9 * close); }
        }
    }
    return best;
}

"""USDA names lead with the main food ("Milk, whole"), so a matching first word ranks higher."""
def match_score(query: str, name: str) -> float {
    wanted = words(query);
    have = words(name);
    if not wanted or not have { return 0.0; }
    coverage = sum([word_credit(word, have) for word in wanted]) / len(wanted);
    if coverage == 0.0 { return 0.0; }
    overall = SequenceMatcher(None, " ".join(wanted), " ".join(have)).ratio();
    leading = 0.1 if word_credit(wanted[0], have[:1]) >= 0.9 else 0.0;
    return 0.7 * coverage + 0.2 * overall + leading;
}

def by_score(pair: tuple[float, dict[str, any]]) -> float {
    return pair[0];
}

def:priv lookup_food(query: str) -> list[dict[str, any]] {
    if not isinstance(query, str) or not 2 <= len(query.strip()) <= 80 {
        raise ValueError("Enter a food name of 2 to 80 characters.");
    }
    results: list[tuple[float, dict[str, any]]] = [];
    for meal in meal_table() {
        score = match_score(query, meal["name"]);
        if score >= 0.55 {
            results.append((score, {"kind": "meal", "name": meal["name"], "calories": meal["calories"], "detail": meal["detail"], "source": "Stride meal idea, per serving"}));
        }
    }
    for food in food_table() {
        score = match_score(query, food["name"]);
        if score >= 0.55 {
            results.append((score, {"kind": "food", "name": food["name"], "kcal_per_100g": food["kcal_per_100g"], "source": "USDA Foundation Foods, per 100 g"}));
        }
    }
    ranked = sorted(results, key=by_score, reverse=True);
    return [item for (score, item) in ranked[:8]];
}
