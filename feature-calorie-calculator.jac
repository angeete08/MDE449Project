"""Food calorie calculator displayed beneath meal advice."""
import from .calorie_data { search_foods, calculate_food_calories }

def:pub CalorieCalculator -> JsxElement {
    has query: str = "", grams: str = "100", selected: str = "",
        foods: list[dict[str, any]] = [], result: dict[str, any] = {},
        message: str = "", busy: bool = False;

    async def search(e: FormEvent) -> None {
        e.preventDefault();
        if busy { return; }
        busy = True; result = {}; selected = ""; foods = [];
        try {
            response = await search_foods(query);
            foods = response["foods"]; message = response["message"];
        } except Exception { message = "Food search is unavailable. Please try again."; }
        finally { busy = False; }
    }

    async def calculate(e: FormEvent) -> None {
        e.preventDefault();
        if busy { return; }
        busy = True; result = {}; message = "";
        try {
            response = await calculate_food_calories(int(selected), float(grams));
            if response["ok"] { result = response; }
            else { message = response["message"]; }
        } except Exception { message = "Could not calculate calories. Please try again."; }
        finally { busy = False; }
    }

    <section className="calorie-calculator" aria-labelledby="calorie-title">
        <div className="section-label">FOOD LOOKUP</div><h2 id="calorie-title">Calculate food calories</h2>
        <p>Search a food, choose its preparation, and enter the edible portion weight in grams.</p>
        <form className="calorie-search" onSubmit={search}>
            <label>Food name<input type="search" required={True} minLength={2} maxLength={120} placeholder="e.g. apple, rice, chicken" value={query} disabled={busy} onChange={lambda (e: ChangeEvent) { query = e.target.value; foods = []; selected = ""; result = {}; message = ""; }}/></label>
            <button className="quiet" type="submit" disabled={busy}>{"Please wait…" if busy else "Search foods"}</button>
        </form>
        {if len(foods) > 0 {
            <form className="calorie-portion" onSubmit={calculate}>
                <label>Matching food<select required={True} value={selected} disabled={busy} onChange={lambda (e: ChangeEvent) { selected = e.target.value; result = {}; }}>
                    <option value="">Choose a food</option>
                    {for food in foods { <option key={food["id"]} value={str(food["id"])}>{food["name"] + (" — calories unavailable" if "kcal_per_100g" not in food else "")}</option> }}
                </select></label>
                <label>Portion weight (g)<input type="number" required={True} min="0.1" max="10000" step="0.1" value={grams} disabled={busy} onChange={lambda (e: ChangeEvent) { grams = e.target.value; result = {}; }}/></label>
                <button className="primary" type="submit" disabled={busy or not selected}>Calculate calories</button>
            </form>
        }}
        <p role="status" aria-live="polite">{message}</p>
        {if result {
            <div className="calorie-result" role="status" aria-live="polite"><strong>{"≈ " + str(result["calories"]) + " kcal"}</strong><p>{result["food"]["name"] + " · " + str(result["grams"]) + " g"}</p><small>{str(result["food"]["kcal_per_100g"]) + " kcal per 100 g · " + result["food"]["energy_basis"] + " · FDC ID " + str(result["food"]["id"])}</small></div>
        }}
        <small>Source: USDA FoodData Central, Foundation Foods · supplied December 18, 2025 dataset. Estimates depend on food preparation and portion weight. This lookup does not change your daily calorie target.</small>
    </section>
}
