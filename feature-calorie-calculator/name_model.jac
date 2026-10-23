"""Fitted character/word TF-IDF retrieval model, not a calorie regression model."""
import math;
import re;
import unicodedata;
import json;
import os;
import from difflib { SequenceMatcher }

glob MODEL_CACHE: dict[str, any] = {};

def normalize_name(value: str) -> str {
    text = unicodedata.normalize("NFKD", value.lower());
    text = "".join([c for c in text if not unicodedata.combining(c)]);
    aliases = {"apples": "apple", "eggs": "egg", "sugars": "sugar", "tomatoes": "tomato", "potatoes": "potato",
        "onions": "onion", "carrots": "carrot", "bananas": "banana", "peppers": "pepper", "mushrooms": "mushroom",
        "raspberries": "raspberry", "blueberries": "blueberry", "strawberries": "strawberry", "nuts": "nut",
        "aubergine": "eggplant", "courgette": "zucchini", "yoghurt": "yogurt"};
    return " ".join(aliases.get(word, word) for word in re.findall("[a-z0-9]+", text));
}

def features(name: str) -> dict[str, float] {
    normalized = normalize_name(name);
    counts: dict[str, float] = {};
    for word in normalized.split() {
        key = "w:" + word;
        counts[key] = counts.get(key, 0.0) + 2.0;
        padded = " " + word + " ";
        for n in [3, 4] {
            for i in range(max(0, len(padded) - n + 1)) {
                key = "c:" + padded[i:i+n];
                counts[key] = counts.get(key, 0.0) + 1.0;
            }
        }
    }
    return counts;
}

def vectorize(name: str, idf: dict[str, float]) -> dict[str, float] {
    vector = {key: count * idf[key] for (key, count) in features(name).items() if key in idf};
    norm = math.sqrt(sum(value * value for value in vector.values()));
    return {key: value / norm for (key, value) in vector.items()} if norm else {};
}

def fit_model(documents: list[dict[str, any]]) -> dict[str, any] {
    frequency: dict[str, int] = {};
    for document in documents {
        for key in features(document["name"]) {
            frequency[key] = frequency.get(key, 0) + 1;
        }
    }
    idf = {key: math.log((1 + len(documents)) / (1 + count)) + 1 for (key, count) in frequency.items()};
    fitted = [{**document, "vector": vectorize(document["name"], idf)} for document in documents];
    return {"version": 1, "method": "word and character 3/4-gram TF-IDF", "idf": idf, "documents": fitted};
}

def load_model() -> dict[str, any] {
    if not MODEL_CACHE {
        with open(os.path.join(os.path.dirname(__file__), "data", "name_matcher.json"), encoding="utf-8") as source {
            MODEL_CACHE.update(json.load(source));
        }
    }
    return MODEL_CACHE;
}

def rank_names(query: str, kind: str = "", limit: int = 5) -> list[dict[str, any]] {
    model = load_model();
    vector = vectorize(query, model["idf"]);
    normalized = normalize_name(query);
    words = normalized.split();
    matches: list[dict[str, any]] = [];
    for document in model["documents"] {
        if kind and document["kind"] != kind { continue; }
        name = normalize_name(document["name"]);
        doc_words = name.split();
        # Every meaningful query token needs a plausible title counterpart.
        coverage = sum(max([SequenceMatcher(None, word, other).ratio() for other in doc_words] or [0.0]) for word in words) / max(1, len(words));
        cosine = sum(value * document["vector"].get(key, 0.0) for (key, value) in vector.items());
        score = cosine * 0.8 + coverage * 0.2;
        base = normalize_name(document["name"].split(",")[0]);
        if normalized == name { score = 1.0; }
        elif document["kind"] == "food" and normalized == base { score = max(score, 0.96); }
        if document["kind"] == "food" and normalized != name {
            for modifier in ["dried", "powder", "juice", "white", "yolk"] {
                if modifier in doc_words and modifier not in words { score -= 0.025; }
            }
        }
        if coverage >= 0.75 and score >= 0.32 {
            matches.append({"id": document["id"], "name": document["name"], "kind": document["kind"], "score": round(score, 4)});
        }
    }
    matches.sort(key=lambda (item: dict[str, any]) { (-item["score"], item["name"], str(item["id"])); });
    return matches[:limit];
}
