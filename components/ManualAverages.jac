import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.field { Field, FieldLabel }
import from ..services.stride { save_health_summary }

def:pub ManualAverages(onSaved: Callable[[dict[str, any]], None]) -> JsxElement {
    has steps: str = "",
        heart: str = "",
        sleep: str = "",
        workouts: str = "";
    has message: str = "",
        busy: bool = False;

    async def save() {
        if busy {
            return;
        }
        busy = True;
        try {
            values: dict[str, any] = {};
            for (key, value) in [
                ("avg_daily_steps", steps),
                ("avg_heart_rate", heart),
                ("avg_sleep_hours", sleep),
                ("avg_workouts_per_week", workouts)
            ] {
                values[key] = float(value) if value.strip() else None;
            }
            result = await save_health_summary(
                values, "Manually entered weekly averages"
            );
            onSaved(result);
            message = "Manual averages saved. Blank fields clear unavailable values.";
        } except Exception {
            message = "Use valid averages: steps 0–100000, heart rate 20–250, sleep 0–24 hours and workouts 0–50. Leave unavailable values blank.";
        } finally {
            busy = False;
        }
    }

    return
        <div className="flex flex-col gap-3 border-t pt-4">
            <h3 className="font-medium">Enter weekly averages manually</h3>
            <p className="text-sm text-muted-foreground">
                Optional. Saving replaces the displayed summary. These values do not fill daily activity logs.
            </p>
            <div className="grid gap-3 sm:grid-cols-2">
                <Field>
                    <FieldLabel htmlFor="avg-steps">Average daily steps</FieldLabel>
                    <Input
                        id="avg-steps"
                        type="number"
                        min="0"
                        max="100000"
                        value={steps}
                        onChange={lambda (e: any) { steps = e.target.value; }}
                    />
                </Field>
                <Field>
                    <FieldLabel htmlFor="avg-heart">
                        Average heart rate (bpm)
                    </FieldLabel>
                    <Input
                        id="avg-heart"
                        type="number"
                        min="20"
                        max="250"
                        step="0.1"
                        value={heart}
                        onChange={lambda (e: any) { heart = e.target.value; }}
                    />
                </Field>
                <Field>
                    <FieldLabel htmlFor="avg-sleep">Average sleep (hours)</FieldLabel>
                    <Input
                        id="avg-sleep"
                        type="number"
                        min="0"
                        max="24"
                        step="0.1"
                        value={sleep}
                        onChange={lambda (e: any) { sleep = e.target.value; }}
                    />
                </Field>
                <Field>
                    <FieldLabel htmlFor="avg-workouts">
                        Average workouts per week
                    </FieldLabel>
                    <Input
                        id="avg-workouts"
                        type="number"
                        min="0"
                        max="50"
                        step="0.1"
                        value={workouts}
                        onChange={lambda (e: any) { workouts = e.target.value; }}
                    />
                </Field>
            </div>
            <Button variant="outline" disabled={busy} onClick={save}>
                Save manual averages
            </Button>
            <p role="status" className="text-sm">{message}</p>
        </div>;
}
