import from ..services.nutrition { daily_food, analyze_food, log_food, set_consumed }
import from ..services.food_lookup { lookup_food }
import from ..services.stride { PlanDay, DailyLog }
import from .ui.button { Button }
import from .ui.input { Input }

async def meal_image(file: any) -> str {
    browser: any = window;
    bitmap: any = await browser.createImageBitmap(file);
    try {
        scale = min(1.0, 1200 / max(int(bitmap.width), int(bitmap.height)));
        canvas: any = document.createElement("canvas") as any;
        canvas.width = max(1, round(bitmap.width * scale));
        canvas.height = max(1, round(bitmap.height * scale));
        ctx: any = canvas.getContext("2d");
        ctx.fillStyle = "#fff";
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
        return canvas.toDataURL("image/jpeg", 0.8);
    } finally {
        bitmap.close();
    }
}

def:pub Nutrition(
    photos: bool, day: str, plan: list[PlanDay], logs: list[DailyLog], target: int
) -> JsxElement {
    has rows: list[dict[str, any]] = [],
        files: list[any] = [],
        dragging: bool = False,
        working: bool = False,
        ready: bool = False,
        notice: str = "",
        food: str = "",
        kcal: str = "",
        request_id: str = "",
        search: str = "",
        matches: list[dict[str, any]] = [],
        picked: dict[str, any] = {},
        grams: str = "100",
        lookup_note: str = "";

    async def reload() {
        rows = await daily_food(day);
        ready = True;
    }
    async can with entry {
        try {
            await reload();
        } except Exception {
            notice = "Could not load today’s food. Reopen this tab to retry.";
        }
    }
    analyzed = [
        r
        for r in rows
        if r["analysis"].get("level")
    ];
    eaten = [
        r
        for r in rows
        if r["consumed"]
    ];
    intake = 0;
    for row in eaten {
        intake += row["calories"];
    }
    done = 0;
    burned = 0;
    for workout in plan {
        if workout.date == day and workout.feedback and not workout.is_rest {
            done += 1;
        }
    }
    for log in logs {
        if log.date == day {
            done += log.extra_activities or 0;
            burned = log.calories_burned;
        }
    }
    net = intake - burned;
    levels = ["Very low", "Low", "Moderate", "High", "Very high"];

    picker_disabled = working or not ready or len(analyzed) >= 10;

    def select_photos(selected: list[any]) {
        if picker_disabled or not len(selected) { return; }
        notice = "";
        if len(selected) + len(analyzed) > 10 {
            notice = "Select up to " + str(10 - len(analyzed)) + " photos in total for this batch.";
            return;
        }
        for file in selected {
            if file.type not in ["image/jpeg", "image/png", "image/webp"]
                or file.size > 20000000 {
                notice = "Choose JPEG, PNG or WebP photos under 20 MB each.";
                return;
            }
        }
        files = selected;
    }

    def choose(e: any) {
        select_photos(Array.from(e.target.files));
        e.target.value = "";
    }

    def drag_over(e: any) {
        e.preventDefault();
        dragging = not picker_disabled and "Files" in Array.from(e.dataTransfer.types);
        e.dataTransfer.dropEffect = "copy" if dragging else "none";
    }

    def drop_photos(e: any) {
        e.preventDefault();
        dragging = False;
        dropped: list[any] = Array.from(e.dataTransfer.files);
        if len(dropped) { select_photos([*files, *dropped]); }
    }
    async def analyze() {
        if working {
            return;
        }
        working = True;
        outcomes: list[str] = [];
        pending: list[any] = [];
        try {
            for (i, file) in enumerate(files) {
                notice = "Analyzing photo "
                    + str(i + 1)
                    + " of "
                    + str(len(files))
                    + "…";
                outcome = "";
                try {
                    outcome = await analyze_food(day, await meal_image(file));
                } except Exception {
                    outcome = "could not read or upload photo";
                }
                outcomes.append(file.name + " — " + outcome);
                if outcome not in ["analyzed", "already analyzed"] {
                    pending.append(file);
                }
            }
            files = pending;
            notice = " · ".join(outcomes);
            await reload();
        } except Exception {
            notice = "Reopen this tab to refresh saved results.";
        } finally {
            working = False;
        }
    }
    async def toggle(row: dict[str, any]) {
        working = True;
        try {
            await set_consumed(day, row["token"], not row["consumed"]);
            await reload();
            notice = "Food log updated.";
        } except Exception {
            notice = "Could not update food log. Try again.";
        } finally {
            working = False;
        }
    }
    # Offline fallback: bundled USDA foods and Stride meal ideas, no photo model needed.
    async def find_food() {
        picked = {};
        try {
            matches = await lookup_food(search);
            lookup_note = "" if len(matches) > 0 else "No match in the offline list. Try a simpler name or enter calories yourself.";
        } except Exception {
            matches = [];
            lookup_note = "Enter a food name of 2 to 80 characters.";
        }
    }
    def fill_from(item: dict[str, any], amount: str) {
        picked = item;
        grams = amount;
        if item["kind"] == "meal" {
            food = item["name"];
            kcal = str(item["calories"]);
        } elif amount.isdigit() and 0 < int(amount) <= 5000 {
            food = item["name"] + " (" + amount + " g)";
            kcal = str(round(item["kcal_per_100g"] * int(amount) / 100));
        }
    }
    async def add() {
        if not kcal.isdigit() or int(kcal) > 20000 or not food.strip() {
            notice = "Enter a food name and 0–20000 whole calories.";
            return;
        }
        working = True;
        browser: any = window;
        token = request_id or str(browser.crypto.randomUUID());
        request_id = token;
        try {
            await log_food(day, token, food, int(kcal));
            await reload();
            request_id = "";
            food = "";
            kcal = "";
            picked = {};
            matches = [];
            search = "";
            notice = "Added to today’s intake.";
        } except Exception {
            notice = "Could not save this food. Try again.";
        } finally {
            working = False;
        }
    }
    if not ready {
        return <p role="status">{notice or "Loading today’s food log…"}</p>;
    }
    return
        <section className="nutrition">
            {if photos {
                <div className="nutrition-panel">
                    <h2>Got your nutritions?</h2>
                    <p>
                        Choose a meal or snack photo to estimate its nutrients and calories with Gemini.
                    </p>
                    <label className={"nutrition-picker is-dragging" if dragging else "nutrition-picker"}
                        onDragOver={drag_over}
                        onDragLeave={lambda (e: any) {
                            if not e.currentTarget.contains(e.relatedTarget) { dragging = False; }
                        }}
                        onDrop={drop_photos}>
                        Drop meal photos here
                        <input
                            className="sr-only"
                            aria-label="Choose meal photos"
                            type="file"
                            multiple={True}
                            accept="image/jpeg,image/png,image/webp"
                            disabled={picker_disabled}
                            onChange={choose}
                        />
                        <span className="nutrition-browse">Choose files</span>
                        <small>
                            {str(len(analyzed))
                                + " / 10 photos analyzed today · JPEG, PNG or WebP"}
                        </small>
                    </label>
                    {len(files) > 0 and <p>{", ".join([f.name for f in files])}</p>}
                    <Button
                        disabled={working or not ready or len(files) == 0}
                        onClick={analyze}
                    >
                        Analyze photos
                    </Button>
                </div>
            } else {
                <div className="nutrition">
                    <div className="nutrition-panel">
                        <h2>Daily calorie tracker</h2>
                        <div
                            className="intake-ring"
                            style={{
                                "background": "conic-gradient(#11966b "
                                    + str(min(100.0, intake * 100 / max(1, target)))
                                    + "%, #e0eee8 0)"
                            }}
                        >
                            <div>
                                <small>Calories consumed</small>
                                <strong>{intake}</strong>
                                <span>{"of " + str(target) + " kcal"}</span>
                            </div>
                        </div>
                        <div className="nutrition-stats">
                            <div>
                                <span
                                    className="stride-runner"
                                    aria-hidden="true"
                                ></span>
                                <strong>{done}</strong>
                                <span>Done</span>
                            </div>
                            <div>
                                <span aria-hidden="true">🔥</span>
                                <strong>{burned}</strong>
                                <span>Total Calories Burned</span>
                            </div>
                        </div>
                    </div>
                    <div className="nutrition-panel">
                        <div className="scale-labels">
                            <h2>Today's Energy Balance</h2>
                            <small>{day}</small>
                        </div>
                        <p>
                            <i>Calories in, Calories out</i>
                        </p>
                        <div className="energy-flow">
                            <div>
                                <strong>{intake}</strong>
                                Energy (In)
                            </div>
                            <span>→</span>
                            <div>
                                <strong>{burned}</strong>
                                Energy (Out)
                            </div>
                            <span>→</span>
                            <div>
                                <strong>{("+" if net > 0 else "") + str(net)}</strong>
                                Net Value
                            </div>
                        </div>
                        <small>
                            All values in kcal. Energy out uses your logged calories burned.
                        </small>
                    </div>
                    <div className="nutrition-panel">
                        <h2>Today's food log</h2>
                        <div className="food-lookup">
                            <label>
                                Look up calories (works offline)
                                <Input
                                    maxLength="80"
                                    value={search}
                                    placeholder="e.g. banana, chicken breast, bean tacos"
                                    onChange={lambda (e: any) { search = e.target.value; }}
                                />
                            </label>
                            <Button variant="outline" disabled={working or len(search.strip()) < 2} onClick={find_food}>
                                Look up
                            </Button>
                        </div>
                        {lookup_note and <small>{lookup_note}</small>}
                        {len(matches) > 0 and <div className="food-matches">
                            {for item in matches {
                                <button
                                    type="button"
                                    key={item["kind"] + item["name"]}
                                    className={"food-match is-picked" if picked.get("name") == item["name"] else "food-match"}
                                    onClick={lambda { fill_from(item, grams); }}
                                >
                                    <span>{item["name"]}</span>
                                    <small>{(str(item["calories"]) + " kcal per serving" if item["kind"] == "meal" else str(item["kcal_per_100g"]) + " kcal per 100 g") + " · " + item["source"].split(",")[0]}</small>
                                </button>
                            }}
                        </div>}
                        {picked.get("kind") == "food" and <label className="food-grams">
                            Portion (grams)
                            <Input
                                type="number"
                                min="1"
                                max="5000"
                                value={grams}
                                onChange={lambda (e: any) { fill_from(picked, e.target.value); }}
                            />
                        </label>}
                        {bool(picked) and <small>Estimate from bundled data. Check the name and portion, then add it.</small>}
                        <div className="food-form">
                            <label>
                                Meal or snack
                                <Input
                                    maxLength="100"
                                    value={food}
                                    onChange={lambda (e: any) { food = e.target.value; }}
                                />
                            </label>
                            <label>
                                Calories (kcal)
                                <Input
                                    type="number"
                                    min="0"
                                    max="20000"
                                    value={kcal}
                                    onChange={lambda (e: any) { kcal = e.target.value; }}
                                />
                            </label>
                            <Button disabled={working or not ready} onClick={add}>
                                Add food
                            </Button>
                        </div>
                        {ready and len(eaten) == 0 and <p>No food logged today.</p>}
                        {for row in eaten {
                            <div className="food-row" key={row["token"]}>
                                <span>{row["title"]}</span>
                                <b>{str(row["calories"]) + " kcal"}</b>
                                <Button
                                    variant="outline"
                                    disabled={working}
                                    onClick={lambda { toggle(row); }}
                                >
                                    Remove
                                </Button>
                            </div>
                        }}
                    </div>
                </div>
            } }
            {notice and <p role="status">{notice}</p>}
            {photos
                and <div className="nutrition">
                    {for row in analyzed {
                        <article className="nutrition-panel" key={row["token"]}>
                            <h2>{row["title"]}</h2>
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
                            <Button
                                variant="outline"
                                disabled={working}
                                onClick={lambda { toggle(row); }}
                            >
                                {"Remove from today’s intake"
                                    if row["consumed"]
                                    else "Add to today’s intake"}
                            </Button>
                        </article>
                    }}
                </div>}
        </section>;
}
