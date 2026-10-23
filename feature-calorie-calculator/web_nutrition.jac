"""Google snippet fallback via SerpAPI. Values remain sourced estimates."""
import os;
import re;
import json;
import time;
import uuid;
import threading;
import from urllib.parse { urlencode, urlparse }
import from urllib.request { urlopen }
import from name_model { normalize_name }

glob SEARCH_CACHE: dict[str, any] = {};
glob VALUE_CACHE: dict[str, any] = {};
glob REQUEST_TIMES: list[float] = [];
glob SEARCH_LOCK = threading.Lock();

def valid_source(url: str) -> bool {
    parsed = urlparse(url);
    return parsed.scheme == "https" and bool(parsed.hostname) and not parsed.username and not parsed.password;
}

def parse_search(payload: dict[str, any], name: str, measure: str, kind: str) -> dict[str, any] {
    candidates: list[dict[str, any]] = [];
    items = payload.get("organic_results", []);
    if not isinstance(items, list) { items = []; }
    items = items[:5];
    if isinstance(payload.get("answer_box"), dict) { items = [payload["answer_box"]] + items; }
    for item in items {
        if not isinstance(item, dict) { continue; }
        url = item.get("link", "");
        if not isinstance(url, str) or not valid_source(url) { continue; }
        text = str(item.get("title", "")) + " " + str(item.get("snippet", item.get("answer", "")));
        normalized = normalize_name(text);
        if not all(word in normalized.split() for word in normalize_name(name).split()) { continue; }
        snippet = str(item.get("snippet", item.get("answer", ""))).lower();
        matches: list[any] = [];
        if kind == "calories" {
            for pattern in [r"(?<![\w.,+-])(\d+(?:\.\d+)?)\s*(?:kcal|calories)\s*(?:per|/|in)\s*100\s*(?:g\b|grams\b)", r"100\s*(?:g\b|grams\b)\s*(?:contains?|provides?|[:=])\s*(\d+(?:\.\d+)?)\s*(?:kcal|calories)"] {
                matches += re.findall(pattern, snippet);
            }
        } else {
            # Require the exact recipe quantity followed by its gram weight.
            quantity = measure.lower().strip();
            if not re.match(r"^\d", quantity) { continue; }
            pattern = r"(?<![\w/+-])" + re.escape(quantity) + r"\s*(?:of\s+)?" + re.escape(name.lower()) + r"\s*(?:weighs?|is|equals?|[:=]|\()\s*(\d+(?:\.\d+)?)\s*(?:g\b|grams\b)";
            matches = re.findall(pattern, snippet);
        }
        values = {float(value) for value in matches};
        if len(values) != 1 { continue; }
        value = next(iter(values));
        upper = 1000 if kind == "calories" else 10000;
        if value < 0 or value > upper or (kind == "weight" and value == 0) { continue; }
        candidates.append({"value": value, "url": url, "title": str(item.get("title", "Source")), "snippet": snippet[:500], "kind": kind});
    }
    if not candidates { return {"ok": False, "message": "No explicit, matching value found online. Enter a weight or package-label calories."}; }
    all_values = [float(item["value"]) for item in candidates];
    if max(all_values) - min(all_values) > max(1.0, min(all_values) * 0.1) {
        return {"ok": False, "message": "Online sources disagree. Enter a weight or package-label calories."};
    }
    return {"ok": True, **candidates[0]};
}

def google_lookup(name: str, measure: str, kind: str) -> dict[str, any] {
    key = os.environ.get("SERPAPI_API_KEY", "");
    if not key { return {"ok": False, "message": "Online lookup is not configured. Enter the missing values manually."}; }
    query = name + " calories kcal per 100 g" if kind == "calories" else measure + " " + name + " weight in grams";
    now = time.time();
    with SEARCH_LOCK {
        cached = SEARCH_CACHE.get(query, {});
        if cached and now - cached["time"] < 3600 { return cached["result"]; }
        REQUEST_TIMES[:] = [stamp for stamp in REQUEST_TIMES if now - stamp < 60];
        if len(REQUEST_TIMES) >= 30 { return {"ok": False, "message": "Online lookup limit reached. Try again in a minute or enter values manually."}; }
        REQUEST_TIMES.append(now);
    }
    result: dict[str, any] = {};
    try {
        params = urlencode({"engine": "google", "q": query, "api_key": key, "hl": "en", "gl": "us"});
        with urlopen("https://serpapi.com/search.json?" + params, timeout=5) as response {
            payload = json.loads(response.read(2000000));
        }
        if not isinstance(payload, dict) or payload.get("error") { raise ValueError("Search failed"); }
        result = parse_search(payload, name, measure, kind);
    } except Exception {
        # Never return exception URLs: they may contain the API key.
        return {"ok": False, "message": "Online lookup is unavailable. Enter the missing values manually."};
    }
    with SEARCH_LOCK {
        if result["ok"] {
            lookup_id = str(uuid.uuid4());
            result["lookup_id"] = lookup_id;
            VALUE_CACHE[lookup_id] = {**result, "name": name, "time": now};
        }
        if len(SEARCH_CACHE) >= 256 { SEARCH_CACHE.clear(); }
        for record_id in list(VALUE_CACHE) {
            if now - VALUE_CACHE[record_id]["time"] >= 3600 { VALUE_CACHE.pop(record_id); }
        }
        SEARCH_CACHE[query] = {"time": now, "result": result};
    }
    return result;
}

def web_calorie_record(lookup_id: str, name: str) -> dict[str, any] {
    with SEARCH_LOCK { record = VALUE_CACHE.get(lookup_id, {}); }
    if record and record["kind"] == "calories" and record["name"] == name and time.time() - record["time"] < 3600 { return record; }
    return {};
}
