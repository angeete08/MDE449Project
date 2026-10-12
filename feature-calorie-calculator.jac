"""One-step best-match lookup and optional ingredient-weight recipe estimates."""
import from .recipe_calories { match_calories, resolve_match, suggest_ingredient, estimate_recipe }

def:pub CalorieCalculator -> JsxElement {
    has query: str = "", grams: str = "100", servings: str = "1",
        result: dict[str, any] = {}, estimate: dict[str, any] = {},
        rows: list[dict[str, any]] = [], alternatives: list[dict[str, any]] = [],
        message: str = "", busy: bool = False, showIngredients: bool = False;

    def acceptMatch(response: dict[str, any]) -> None {
        estimate = {}; servings = "1";
        if not response["ok"] { result = {}; rows = []; message = response["message"]; return; }
        result = response; rows = response.get("rows", []);
        showIngredients = response["kind"] == "recipe" and not bool(response.get("proxy", {}));
        message = "Check the suggested match; similar names can describe different foods." if response.get("tentative") else "";
    }

    async def search(e: FormEvent) -> None {
        e.preventDefault();
        if busy { return; }
        busy = True; message = ""; result = {}; estimate = {}; rows = []; alternatives = [];
        try {
            response = await match_calories(query, float(grams));
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
        updated: dict[str, any] = {**rows[index]};
        updated[key] = value;
        if key == "name" { updated["food_id"] = ""; }
        rows = [updated if i == index else row for (i, row) in enumerate(rows)];
        estimate = {}; message = "";
    }

    def matchedName(row: dict[str, any]) -> str {
        for candidate in row["candidates"] {
            if str(candidate["id"]) == row["food_id"] { return candidate["name"]; }
        }
        return "No match — choose a food below";
    }

    async def rematch(index: int) -> None {
        if busy { return; }
        busy = True; estimate = {}; message = "";
        try {
            candidates = await suggest_ingredient(rows[index]["name"]);
            rows = [{**row, "candidates": candidates, "food_id": str(candidates[0]["id"]) if candidates else ""} if i == index else row for (i, row) in enumerate(rows)];
            if not candidates { message = "No ingredient match. Try another name in that row."; }
        } except Exception { message = "Ingredient matching is unavailable. Please try again."; }
        finally { busy = False; }
    }

    async def calculateRecipe(e: FormEvent) -> None {
        e.preventDefault();
        if busy { return; }
        busy = True; message = ""; estimate = {};
        try {
            values = [{"food_id": int(row["food_id"] or "0"), "grams": float(row["grams"]), "manual_kcal": float(row["manual_kcal"]) if row["manual_kcal"] != "" else None} for row in rows];
            response = await estimate_recipe(result["id"], values, int(servings));
            if response["ok"] { estimate = response; }
            else { message = response["message"]; }
        } except Exception { message = "Check every ingredient match and weight, then try again."; }
        finally { busy = False; }
    }

    <section className="calorie-calculator" aria-labelledby="calorie-title">
        <div className="section-label">FOOD & RECIPE LOOKUP</div><h2 id="calorie-title">Calculate food calories</h2>
        <p>Enter a food or recipe name. We’ll suggest the closest match automatically.</p>
        <form className="calorie-search" onSubmit={search}>
            <label>Food or recipe name<input type="search" required={True} minLength={2} maxLength={120} placeholder="e.g. hummus, apple, chicken curry" value={query} disabled={busy} onChange={lambda (e: ChangeEvent) { query = e.target.value; result = {}; rows = []; estimate = {}; alternatives = []; message = ""; }}/></label>
            <label>Food portion (g)<input type="number" min="0.1" max="10000" step="0.1" required={True} value={grams} disabled={busy} onChange={lambda (e: ChangeEvent) { grams = e.target.value; result = {}; rows = []; estimate = {}; alternatives = []; message = ""; }}/></label>
            <button className="primary" type="submit" disabled={busy}>{"Finding a match…" if busy else "Find calories"}</button>
        </form>
        <small>Portion weight applies to USDA food estimates. Whole recipes use ingredient weights and servings below.</small>
        <p role="status" aria-live="polite">{message}</p>
        {if result {
            <div className="calorie-result" role="status" aria-live="polite">
                <span className="section-label">SUGGESTED MATCH</span><h3>{result["name"]}</h3>
                {if result["kind"] == "food" {
                    <strong>{"≈ " + str(result["calories"]) + " kcal"}</strong>
                    <p>{str(result["grams"]) + " g · " + str(result["food"]["kcal_per_100g"]) + " kcal per 100 g"}</p>
                    <small>{"USDA · " + result["food"]["energy_basis"] + " · FDC ID " + str(result["food"]["id"])}</small>
                } else {
                    <a href={result["url"]} target="_blank" rel="noreferrer">View recipe on TheMealDB ↗</a>
                    if bool(result["proxy"]) {
                        <p><strong>{"≈ " + str(result["proxy"]["calories"]) + " kcal"}</strong>{" for " + str(result["proxy"]["grams"]) + " g"}</p>
                        <p>{"Approximation using USDA “" + result["proxy"]["food"]["name"] + "”. This is not measured nutrition for this recipe."}</p>
                        <button className="quiet" type="button" disabled={busy} onClick={lambda { showIngredients = not showIngredients; }}>{"Hide ingredient estimate" if showIngredients else "Estimate using my ingredients"}</button>
                    } else { <p>This recipe has no calorie label. Use the suggested ingredient matches below to estimate it.</p> }
                }}
            </div>
            if len(alternatives) > 0 {
                <details className="match-alternatives"><summary>Not the right match?</summary><div>{for candidate in alternatives {
                    <button className="quiet" key={candidate["kind"] + str(candidate["id"])} disabled={busy} type="button" onClick={lambda { choose(candidate); }}>{candidate["name"] + " · " + ("Recipe" if candidate["kind"] == "recipe" else "USDA")}</button>
                }}</div></details>
            }
            if showIngredients {
                <form className="recipe-ingredients" onSubmit={calculateRecipe}>
                    <h3>Estimate from ingredients</h3><p>Review the suggested USDA foods and enter the grams you actually use. Weight-based recipe quantities are prefilled; cups, counts, and “to taste” need a weight. All ingredients are required.</p>
                    {for (i, row) in enumerate(rows) {
                        <div className="ingredient-row" key={str(i)}>
                            <p><strong>{str(i + 1) + ". " + result["rows"][i]["name"]}</strong>{" · recipe amount: " + (row["measure"] or "not specified")}</p>
                            <label>{"Weight " + str(i + 1) + " (g)"}<input type="number" min="0.1" max="10000" step="0.1" required={True} value={row["grams"]} disabled={busy} onChange={lambda (e: ChangeEvent) { editRow(i, "grams", e.target.value); }}/></label>
                            <p>{"Using your label calories" if row["manual_kcal"] != "" else "Suggested food: " + matchedName(row)}</p>
                            <details open={not row["food_id"]}><summary>Change ingredient match</summary>
                            <div className="ingredient-search"><label>{"Ingredient search " + str(i + 1)}<input value={row["name"]} maxLength={120} disabled={busy} onChange={lambda (e: ChangeEvent) { editRow(i, "name", e.target.value); }}/></label>
                            <button className="quiet" type="button" disabled={busy} onClick={lambda { rematch(i); }}>Find ingredient</button></div>
                            <label>{"USDA match " + str(i + 1)}<select required={row["manual_kcal"] == ""} value={row["food_id"]} disabled={busy} onChange={lambda (e: ChangeEvent) { editRow(i, "food_id", e.target.value); }}><option value="">Choose a food or use label calories</option>{for candidate in row["candidates"] { <option key={candidate["id"]} value={str(candidate["id"])}>{candidate["name"]}</option> }}</select></label>
                            <label>{"Label calories " + str(i + 1) + " (kcal per 100 g, optional)"}<input type="number" min="0" max="1000" step="any" value={row["manual_kcal"]} disabled={busy} onChange={lambda (e: ChangeEvent) { editRow(i, "manual_kcal", e.target.value); }}/></label><small>A value here replaces the suggested USDA value. Use your package label when the dataset has no suitable food.</small>
                            </details>
                        </div>
                    }}
                    <label>Recipe servings<input type="number" min="1" max="100" step="1" required={True} value={servings} disabled={busy} onChange={lambda (e: ChangeEvent) { servings = e.target.value; estimate = {}; }}/></label>
                    <button className="primary" type="submit" disabled={busy}>Estimate recipe calories</button>
                    {if estimate {
                        <div className="calorie-result" role="status" aria-live="polite"><strong>{"≈ " + str(estimate["per_serving"]) + " kcal per serving"}</strong><p>{str(estimate["total"]) + " kcal for all ingredients · " + str(estimate["servings"]) + " servings"}</p><small>{str(estimate["manual_count"]) + " user-entered calorie values. Ingredient-based estimate; cooking losses are not modeled."}</small>
                            <details><summary>Calculation details</summary>{for (j, part) in enumerate(estimate["breakdown"]) { <p key={str(j)}>{part["ingredient"] + " → " + part["food"] + ": " + str(part["grams"]) + " g = " + str(part["calories"]) + " kcal"}</p> }}</details>
                        </div>
                    }}
                </form>
            }
        }}
        <small>Recipes: TheMealDB · Nutrition: USDA Foundation Foods. Name similarity suggests a match; it does not predict nutrition or change your daily calorie target.</small>
    </section>
}
