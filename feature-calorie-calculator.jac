"""One-step best-match lookup and optional ingredient-weight recipe estimates."""
import from .recipe_calories { match_calories, resolve_match, find_ingredient, estimate_recipe }
import from .local_calories { estimate_local_food }

def:pub CalorieCalculator -> JsxElement {
    has query: str = "", grams: str = "100", servings: str = "1", recipeScale: str = "1", appliedScale: float = 1.0,
        result: dict[str, any] = {}, estimate: dict[str, any] = {},
        rows: list[dict[str, any]] = [], alternatives: list[dict[str, any]] = [],
        message: str = "", busy: bool = False, showIngredients: bool = False, revision: int = 0, mode: str = "local";

    def acceptMatch(response: dict[str, any]) -> None {
        revision += 1;
        estimate = {}; servings = "1"; recipeScale = "1"; appliedScale = 1.0;
        if not response["ok"] { result = {}; rows = []; message = response["message"]; return; }
        result = response; rows = response.get("rows", []);
        showIngredients = response["kind"] == "recipe";
        message = "Check the suggested match; similar names can describe different foods." if response.get("tentative") else "";
        automatic = response.get("estimate", {});
        if bool(automatic) {
            if automatic["ok"] { estimate = automatic; }
            else { message = automatic["message"]; }
        }
    }

    async def search(e: FormEvent) -> None {
        e.preventDefault();
        if busy { return; }
        busy = True; message = ""; result = {}; estimate = {}; rows = []; alternatives = [];
        try {
            response = await estimate_local_food(query, float(grams)) if mode == "local" else await match_calories(query, float(grams));
            alternatives = response.get("alternatives", []);
            acceptMatch(response);
        } except Exception { message = "Matching is unavailable. Please try again."; }
        finally { busy = False; }
    }

    async def choose(candidate: dict[str, any]) -> None {
        if busy { return; }
        busy = True; message = "";
        try { acceptMatch(await resolve_match(candidate["kind"], str(candidate["id"]), float(grams))); }
        except Exception { message = "Could not load this match. Please try again."; }
        finally { busy = False; }
    }

    def editRow(index: int, key: str, value: str) -> None {
        revision += 1;
        updated: dict[str, any] = {**rows[index]};
        updated[key] = value;
        if key == "name" { updated["food_id"] = ""; updated["calorie_source"] = {}; }
        if key == "grams" { updated["weight_source"] = {}; updated["weight_basis"] = "User-entered weight"; }
        if key == "food_id" and value { updated["calorie_source"] = {}; }
        rows = [updated if i == index else row for (i, row) in enumerate(rows)];
        estimate = {}; message = "";
    }

    def matchedName(row: dict[str, any]) -> str {
        for candidate in row["candidates"] {
            if str(candidate["id"]) == row["food_id"] { return candidate["name"]; }
        }
        return "No match — choose a food below";
    }

    def scaleRecipe(value: str) {
        revision += 1;
        recipeScale = value; estimate = {};
        try {
            scale = float(value);
            if not (scale >= 0.1 and scale <= 10) {
                message = "Choose a recipe scale from 0.1 to 10."; return;
            }
            rows = [{**row, "grams": str(round(float(row["grams"]) * scale / appliedScale, 1)) if row["grams"] else ""} for row in rows];
            appliedScale = scale; message = "";
        } except Exception { message = "Choose a recipe scale from 0.1 to 10."; }
    }

    async def rematch(index: int) -> None {
        if busy { return; }
        busy = True; estimate = {}; message = "";
        try {
            response = await find_ingredient(rows[index]["name"]);
            candidates = response["candidates"];
            rows = [{**row, **response, "food_id": str(candidates[0]["id"]) if len(candidates) > 0 and not bool(response["calorie_source"]) else ""} if i == index else row for (i, row) in enumerate(rows)];
            revision += 1;
            if len(candidates) == 0 and not bool(response["calorie_source"]) { message = response["lookup_message"]; }
        } except Exception { message = "Ingredient matching is unavailable. Please try again."; }
        finally { busy = False; }
        await refreshEstimate();
    }

    async def refreshEstimate(e: any = None) {
        if not bool(result) or result["kind"] != "recipe" { return; }
        current = revision; recipeId = result["id"];
        try {
            if not recipeScale or float(recipeScale) != appliedScale { return; }
            values = [{"food_id": int(row["food_id"] or "0"), "grams": float(row["grams"]) if row["grams"] else None, "manual_kcal": float(row["manual_kcal"]) if row["manual_kcal"] != "" else None,
                "web_lookup_id": row["calorie_source"].get("lookup_id", "") if not row["food_id"] and row["manual_kcal"] == "" else ""} for row in rows];
            response = await estimate_recipe(recipeId, values, int(servings));
            if current != revision or not bool(result) or result["id"] != recipeId { return; }
            estimate = response if response["ok"] else {};
            message = "" if response["ok"] else response["message"];
        } except Exception {
            if current == revision { message = "Check the unresolved ingredient values."; }
        }
    }

    async def changeScale(e: ChangeEvent) {
        scaleRecipe(e.target.value); await refreshEstimate();
    }

    async def changeServings(e: ChangeEvent) {
        revision += 1; servings = e.target.value; estimate = {}; await refreshEstimate();
    }

    async def calculateRecipe(e: FormEvent) -> None {
        e.preventDefault();
        await refreshEstimate();
    }

    <section className="calorie-calculator" aria-labelledby="calorie-title">
        <div className="section-label">FOOD & RECIPE LOOKUP</div><h2 id="calorie-title">Calculate food calories</h2>
        <p>Enter a food or dish name for a rough calorie estimate. Local mode uses Qwen on this computer, without web searches or ingredient matching.</p>
        <label>Estimation mode<select value={mode} disabled={busy} onChange={lambda (e: ChangeEvent) { revision += 1; mode = e.target.value; result = {}; rows = []; estimate = {}; alternatives = []; message = ""; }}><option value="local">Local Qwen estimate (default)</option><option value="evidence">Evidence and recipe ingredients</option></select></label>
        <form className="calorie-search" onSubmit={search}>
            <label>Food or recipe name<input type="search" required={True} minLength={2} maxLength={120} placeholder="e.g. hummus, apple, chicken curry" value={query} disabled={busy} onChange={lambda (e: ChangeEvent) { query = e.target.value; result = {}; rows = []; estimate = {}; alternatives = []; message = ""; }}/></label>
            <details><summary>Food portion: {grams + " g"}</summary><label>Food portion (g)<input type="number" min="0.1" max="10000" step="0.1" required={True} value={grams} disabled={busy} onChange={lambda (e: ChangeEvent) { revision += 1; grams = e.target.value; result = {}; rows = []; estimate = {}; alternatives = []; message = ""; }}/></label></details>
            <button className="primary" type="submit" disabled={busy}>{"Searching and estimating…" if busy else "Find calories"}</button>
        </form>
        <small>Foods default to 100 g. Recipes default to the complete listed batch. Portion, scale, and servings are optional adjustments.</small>
        <p role="status" aria-live="polite">{message}</p>
        {if bool(result) {
            <div className="calorie-result" role="status" aria-live="polite">
                <span className="section-label">SUGGESTED MATCH</span><h3>{result["name"]}</h3>
                {if result["kind"] == "food" {
                    <strong>{"≈ " + str(result["calories"]) + " kcal"}</strong>
                    <p>{str(result["grams"]) + " g · " + str(result["food"]["kcal_per_100g"]) + " kcal per 100 g"}</p>
                    if result.get("local_model") {
                        <p>{"Model estimate · " + result["local_model"] + " · " + result["preparation"]}</p><p>{result["assumptions"]}</p><small>Unverified model estimate. Actual calories vary with recipe, preparation, and portion. This result has no retrieved nutrition source.</small>
                    } elif result.get("web_source") {
                        <p>{"Agent-selected USDA nutrition estimate. Review the retrieved food and explanation." if result["web_source"].get("agent", False) else "Online estimate from Google results. Check preparation and source before using it."}</p><a href={result["web_source"]["url"]} target="_blank" rel="noreferrer">{result["web_source"]["title"] + " ↗"}</a>
                        <p>{result["web_source"].get("explanation", "")}</p>
                    } else { <small>{"USDA · " + result["food"]["energy_basis"] + " · FDC ID " + str(result["food"]["id"])}</small> }
                } else {
                    <a href={result["url"]} target="_blank" rel="noreferrer">View recipe on TheMealDB ↗</a>
                    if bool(result["proxy"]) {
                        <p><strong>{"≈ " + str(result["proxy"]["calories"]) + " kcal"}</strong>{" for " + str(result["proxy"]["grams"]) + " g"}</p>
                        <p>{"Approximation using USDA “" + result["proxy"]["food"]["name"] + "”. This is not measured nutrition for this recipe."}</p>
                        <button className="quiet" type="button" disabled={busy} onClick={lambda { showIngredients = not showIngredients; }}>{"Hide ingredient estimate" if showIngredients else "Estimate using my ingredients"}</button>
                    } else { <p>This recipe has no calorie label. Ingredient totals calculate automatically when all values are available.</p> }
                }}
            </div>
            if len(alternatives) > 0 {
                <details className="match-alternatives"><summary>Not the right match?</summary><div>{for candidate in alternatives {
                    <button className="quiet" key={candidate["kind"] + str(candidate["id"])} disabled={busy} type="button" onClick={lambda { choose(candidate); }}>{candidate["name"] + " · " + ("Recipe" if candidate["kind"] == "recipe" else "USDA")}</button>
                }}</div></details>
            }
            if showIngredients {
                <form className="recipe-ingredients" onSubmit={calculateRecipe}>
                    <h3>Recipe estimate</h3><p>Google values are preferred; recipe mass, local foods, and labeled kitchen estimates fill gaps. A complete estimate appears automatically. Expand an ingredient only to review or supply an unresolved value.</p>
                    <details><summary>Adjust recipe size · {recipeScale + "× · " + servings + " serving(s)"}</summary>
                    <label>Recipe scale<input type="number" min="0.1" max="10" step="0.1" required={True} value={recipeScale} disabled={busy} onChange={changeScale}/></label><small>1× uses the recipe as written; 2× doubles every entered weight.</small>
                    <label>Recipe servings<input type="number" min="1" max="100" step="1" required={True} value={servings} disabled={busy} onChange={changeServings}/></label><small>Default: one complete batch. Set servings only if you want calories per serving.</small></details>
                    {for (i, row) in enumerate(rows) {
                        <details className="ingredient-row" key={result["id"] + ":" + str(i)}>
                            <summary>{str(i + 1) + ". " + result["rows"][i]["name"] + " · " + (row["grams"] + " g" if row["grams"] else "Weight needed") + (" · Agent-assisted estimate" if row["calorie_source"].get("agent", False) else (" · Online estimate" if bool(row["calorie_source"]) or bool(row["weight_source"]) else (" · Calories needed" if not row["food_id"] and row["manual_kcal"] == "" else "")))}</summary>
                            <p>{"Recipe amount at 1×: " + (row["measure"] or "not specified")}</p><small>{row["weight_basis"]}</small>
                            <label>{"Weight " + str(i + 1) + " (g)"}<input type="number" min="0.1" max="10000" step="0.1" required={True} value={row["grams"]} disabled={busy} onBlur={refreshEstimate} onChange={lambda (e: ChangeEvent) { editRow(i, "grams", e.target.value); }}/></label>
                            {if bool(row["weight_source"]) { <p><a href={row["weight_source"]["url"]} target="_blank" rel="noreferrer">Weight source ↗</a></p> }}
                            <p>{"Using your label calories" if row["manual_kcal"] != "" else ("Online estimate: " + str(row["calorie_source"]["value"]) + " kcal per 100 g" if bool(row["calorie_source"]) and not row["food_id"] else "Suggested food: " + matchedName(row))}</p>
                            {if bool(row["calorie_source"]) { <p><a href={row["calorie_source"]["url"]} target="_blank" rel="noreferrer">{row["calorie_source"]["title"] + " ↗"}</a><small>{"Agent-selected USDA evidence; review weight assumptions and preparation." if row["calorie_source"].get("agent", False) else "Google result estimate. Review the source and preparation; override with your package label if needed."}</small></p> }}
                            {if row["lookup_message"] { <p>{row["lookup_message"]}</p> }}
                            <details><summary>Change ingredient match</summary>
                            <div className="ingredient-search"><label>{"Ingredient search " + str(i + 1)}<input value={row["name"]} maxLength={120} disabled={busy} onChange={lambda (e: ChangeEvent) { editRow(i, "name", e.target.value); }}/></label>
                            <button className="quiet" type="button" disabled={busy} onClick={lambda { rematch(i); }}>Find ingredient</button></div>
                            <label>{"USDA match " + str(i + 1)}<select required={row["manual_kcal"] == "" and not bool(row["calorie_source"])} value={row["food_id"]} disabled={busy} onBlur={refreshEstimate} onChange={lambda (e: ChangeEvent) { editRow(i, "food_id", e.target.value); }}><option value="">Choose a food, online estimate, or label calories</option>{for candidate in row["candidates"] { <option key={candidate["id"]} value={str(candidate["id"])}>{candidate["name"]}</option> }}</select></label>
                            <label>{"Label calories " + str(i + 1) + " (kcal per 100 g, optional)"}<input type="number" min="0" max="1000" step="any" value={row["manual_kcal"]} disabled={busy} onBlur={refreshEstimate} onChange={lambda (e: ChangeEvent) { editRow(i, "manual_kcal", e.target.value); }}/></label><small>A value here replaces the suggested USDA value. Use your package label when the dataset has no suitable food.</small>
                            </details>
                        </details>
                    }}
                    {if bool(estimate) {
                        <div className="calorie-result" role="status" aria-live="polite"><strong>{"≈ " + str(estimate["total"]) + " kcal for this batch" if estimate["servings"] == 1 else "≈ " + str(estimate["per_serving"]) + " kcal per serving"}</strong><p>{str(estimate["total"]) + " kcal for all ingredients · " + str(estimate["servings"]) + " servings"}</p><small>{str(estimate["manual_count"]) + " user-entered and " + str(estimate["web_count"]) + " online calorie values. Ingredient-based estimate; cooking losses are not modeled."}</small>
                            <details><summary>Calculation details</summary>{for (j, part) in enumerate(estimate["breakdown"]) { <p key={str(j)}>{part["ingredient"] + " → " + part["food"] + ": " + str(part["grams"]) + " g = " + str(part["calories"]) + " kcal"}{if bool(part["web_source"]) { <a href={part["web_source"]["url"]} target="_blank" rel="noreferrer">Source ↗</a> }}</p> }}</details>
                        </div>
                    }}
                </form>
            }
        }}
        <small>Recipes: TheMealDB · Nutrition: USDA Foundation Foods. Name similarity suggests a match; it does not predict nutrition or change your daily calorie target.</small>
    </section>
}
