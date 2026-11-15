import from ..services.nutrition { review_food }

def:pub PhotoFoodReview(day: str, row: dict[str, any], onSaved: Callable[[], any]) -> JsxElement {
    has title: str = str(row["title"]), kcal: str = str(row["calories"]), busy: bool = False, error: str = "";
    async def save(consumed: bool) {
        if not kcal.isdigit() or not 0 <= int(kcal) <= 20000 or not title.strip() { error = "Enter a name and whole calories from 0 to 20000."; return; }
        busy = True;
        try {
            await review_food(day, row["token"], title, int(kcal), consumed);
            await onSaved();
            error = "";
        } except Exception { error = "Could not save this review. Try again."; }
        finally { busy = False; }
    }
    return <section className="photo-food-review"><p>Review the estimated portion before saving. Your correction replaces this entry, so retries do not add it twice.</p>
        <label>Food name<input maxLength={100} value={title} onChange={lambda (e: any) { title = e.target.value; }}/></label>
        <label>Reviewed calories (kcal)<input type="number" min="0" max="20000" value={kcal} onChange={lambda (e: any) { kcal = e.target.value; }}/></label>
        <button type="button" disabled={busy} onClick={lambda { save(True); }}>{"Save correction to intake" if row["consumed"] else "Confirm & add to intake"}</button>
        {row["consumed"] and <button type="button" disabled={busy} onClick={lambda { save(False); }}>Remove from intake</button>}
        {error and <p role="alert">{error}</p>}
    </section>;
}
