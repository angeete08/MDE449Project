import from .PhotoFoodReview { PhotoFoodReview }

def:pub MealPhotoResult(day: str, row: dict[str, any], onSaved: any, show_title: bool = True) -> JsxElement {
    levels = ["Very low", "Low", "Moderate", "High", "Very high"];
    return
        <article className="nutrition-panel">
            {show_title and <h2>{row["title"]}</h2>}
            <p>{row["analysis"]["description"]}</p>
            <strong>
                {levels[row["analysis"]["level"] - 1]
                    + " nutritional value"}
            </strong>
            <div className="nutrition-scale" aria-hidden="true">
                {for n in [1, 2, 3, 4, 5] {
                    <span
                        key={n}
                        className={"selected"
                            if n == row["analysis"]["level"]
                            else ""}
                    ></span>
                }}
            </div>
            <div className="scale-labels">
                <small>Very low</small>
                <small>Very high</small>
            </div>
            {for (label, field) in [
                ["Processing", "processing"],
                ["Fiber", "fiber"],
                ["Protein", "protein"],
                ["Fat type", "fat"]
            ] {
                <div className="food-row" key={field}>
                    <b>{label}</b>
                    <span>{row["analysis"][field]}</span>
                </div>
            }}
            <p>
                {"Estimated portion · "
                    + str(row["calories"])
                    + " kcal"}
            </p>
            <PhotoFoodReview day={day} row={row} onSaved={onSaved}/>
        </article>;
}
