import from ..services.nutrition { daily_food }
import from ..workout_rules { day_energy }

def:pub EnergyBalance(day: str, state: dict[str, any], logs: list[dict[str, any]]) -> JsxElement {
    has intake: int = 0, ready: bool = False, error: str = "";
    async def load() {
        try {
            rows = await daily_food(day);
            intake = sum([int(row["calories"]) for row in rows if row["consumed"]]);
            ready = True;
            error = "";
        } except Exception { error = "Could not load food intake. Your activity totals are still shown."; }
    }
    async can with entry { await load(); }
    energy = day_energy(state, day, logs);
    net = intake - energy["total"];
    return <section className="nutrition-panel today-energy" data-tour="today-energy" aria-label="Today's Energy Balance">
        <div className="scale-labels"><h2>Today's Energy Balance</h2><time>{day}</time></div>
        <div className="energy-flow">
            <div><strong>{str(intake) if ready else "—"}</strong>Energy (In)</div><span>→</span>
            <div><strong>{energy["total"]}</strong>Energy (Out)</div><span>→</span>
            <div><strong>{(("+" if net > 0 else "") + str(net)) if ready else "—"}</strong>Net Value</div>
        </div>
        <div className="energy-breakdown" role="status"><span>{"Checked workouts: ≈ " + str(energy["workouts"]) + " kcal"}</span><span>{"Logged activities: " + str(energy["logged"]) + " kcal"}</span><strong>{"Total activity energy: " + str(energy["total"]) + " kcal"}</strong></div>
        <p className="text-xs text-muted-foreground">All values in kcal for this date only. Activity energy combines checked workouts and separately logged activities; resting energy is not included. Log checked workouts only once.</p>
        {error and <p role="alert">{error}<button type="button" onClick={load}>Retry intake</button></p>}
    </section>;
}
