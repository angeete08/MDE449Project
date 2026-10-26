import from "@jac/runtime" { useNavigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    ArrowRight01Icon,
    ArrowLeft01Icon,
    DashboardSquare01Icon,
    CheckmarkCircle02Icon
}
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.field { Field, FieldLabel }
import from .ui.switch { Switch }
import from .ui.badge { Badge }
import from .ui.progress { Progress }
import from .ui.select { Select, SelectTrigger, SelectValue, SelectContent, SelectItem }
import from ..lib.utils { cn }
import from ..services.stride { save_profile, get_profile }

glob GOALS: list[dict[str, any]] = [
         {
             "id": "lose_weight",
             "label": "Lose weight",
             "desc": "A routine built around your goal"
         },
         {
             "id": "gain_muscle",
             "label": "Gain muscle",
             "desc": "Strength-focused weekly workouts"
         },
         {
             "id": "stay_active",
             "label": "Stay active",
             "desc": "A balanced routine to keep moving"
         },

     ];

glob LEVELS: list[str] = ["beginner", "intermediate", "advanced"];
glob DIETS: list[dict[str, any]] = [
         {"id": "none", "label": "No restriction"},
         {"id": "vegetarian", "label": "Vegetarian"},
         {"id": "keto", "label": "Keto"},
         {"id": "high_protein", "label": "High protein"},

     ];
glob EQUIPMENT: list[str] = [
         "none",
         "dumbbells",
         "gym",
         "resistance bands",
         "yoga mat"
     ];
glob WEARABLES: list[dict[str, any]] = [
         {"id": "apple_health", "label": "Apple Health"},
         {"id": "oura", "label": "Oura Ring"},
         {"id": "fitbit", "label": "Fitbit"},
         {"id": "garmin", "label": "Garmin"},

     ];

def:pub OnboardingWizard() -> JsxElement {
    has step: int = 1;
    has name: str = "";
    has goal: str = "lose_weight";
    has level: str = "beginner";
    has days_per_week: str = "3";
    has equipment: list[str] = ["none"];
    has diet: str = "none";
    has calorie_target: str = "1900";
    has health_conditions: str = "";
    has store_data: bool = False;
    has wearables: list[str] = [];
    has saving: bool = False;
    has error: str = "";
    nav = useNavigate();

    total_steps = 4;
    def toggle(list_ref: str, value: str) {
        current: list[str] = equipment if list_ref == "equipment" else wearables;
        if value in current {
            current = [
                v
                for v in current
                if v != value
            ];
        } else {
            current = current + [value];
        }
        if list_ref == "equipment" {
            equipment = current;
        } else {
            wearables = current;
        }
    }

    async can with entry {
        try {
            p = await get_profile();
            if p is not None {
                name = p.name;
                goal = p.goal;
                level = p.level;
                days_per_week = str(p.days_per_week);
                equipment = p.equipment;
                diet = p.diet;
                calorie_target = str(p.calorie_target);
                health_conditions = p.health_conditions;
                store_data = p.store_data;
                wearables = p.wearables;
            }
        } except Exception {
            error = "Could not load your profile. Reload before editing existing preferences.";
        }
    }

    async def handle_finish() {
        if saving {
            return;
        }
        saving = True;
        error = "";
        try {
            if not name.strip()
                or not days_per_week.isdigit()
                or not calorie_target.isdigit() {
                error = "Enter your name, whole-number workout days and a calorie target.";
                return;
            }
            d = new(Date);
            mm = str(d.getMonth() + 1);
            dd = str(d.getDate());
            if len(mm) < 2 {
                mm = "0" + mm;
            }
            if len(dd) < 2 {
                dd = "0" + dd;
            }
            stamp = str(d.getFullYear()) + "-" + mm + "-" + dd;
            await save_profile(
                name,
                goal,
                level,
                int(days_per_week),
                equipment,
                diet,
                int(calorie_target),
                health_conditions,
                store_data,
                wearables,
                stamp
            );
            nav("/app");
        } except Exception {
            error = "Could not save. Use 1–6 workout days, a calorie target of 1–10000 and enable account storage.";
        } finally {
            saving = False;
        }
    }

    def OptionCard(
        selected: bool,
        title: str,
        desc: str = "",
        pick: str = "",
        onPick: Callable[[str], None] | None = None
    ) -> JsxElement {
        return
            <button
                type="button"
                onClick={lambda (e: MouseEvent) { if onPick != None { onPick(pick); }}}
                className={cn(
                    "flex flex-col gap-1 rounded-xl border bg-card px-4 py-3 text-left shadow-sm transition-colors hover:bg-muted/60",
                    selected and "border-primary ring-2 ring-primary/30",
                )}
            >
                <span className="text-sm font-medium">{title}</span>
                {desc != ""
                    and <span className="text-xs text-muted-foreground">{desc}</span>}
            </button>;
    }

    return
        <div className="min-h-svh bg-muted/40">
            <div className="mx-auto flex max-w-2xl flex-col gap-8 px-6 py-10">
                <div className="flex items-center gap-2.5">
                    <div
                        className="flex size-8 items-center justify-center rounded-lg bg-primary text-primary-foreground shadow-sm"
                    >
                        <HugeiconsIcon
                            icon={DashboardSquare01Icon}
                            strokeWidth={2}
                            className="size-4"
                        />
                    </div>
                    <span className="text-base font-semibold tracking-tight">
                        Stride
                    </span>
                </div>
                <div className="flex flex-col gap-3">
                    <div className="flex items-center justify-between">
                        <span className="text-sm text-muted-foreground">
                            Step {str(step)} of {str(total_steps)}
                        </span>
                        <Badge variant="secondary">
                            {[
                                "About you",
                                "Your training",
                                "Your diet",
                                "Data and health"
                            ][step - 1]}
                        </Badge>
                    </div>
                    <Progress value={(step * 25) as int}/>
                </div>
                <div
                    className="flex flex-col gap-6 rounded-2xl border bg-card p-6 shadow-sm animate-in fade-in slide-in-from-bottom-2 duration-500"
                >
                    {if step == 1 {
                        <div className="flex flex-col gap-5">
                            <div className="flex flex-col gap-1.5">
                                <h1 className="text-2xl font-semibold tracking-tight">
                                    What should Stride call you?
                                </h1>
                                <p className="text-sm text-muted-foreground">
                                    Your name appears on your private dashboard.
                                </p>
                            </div>
                            <Field>
                                <FieldLabel htmlFor="name">Your name</FieldLabel>
                                <Input
                                    id="name"
                                    placeholder="e.g. Priya Nair"
                                    value={name}
                                    onChange={lambda (e: ChangeEvent) { name = e.target.value; }}
                                    className="h-10"
                                />
                            </Field>
                            <Field>
                                <FieldLabel>{"What is your fitness goal?"}</FieldLabel>
                                <div className="grid gap-2 sm:grid-cols-3">
                                    {for g in GOALS {
                                        <OptionCard
                                            key={g["id"]}
                                            selected={goal == g["id"]}
                                            title={g["label"]}
                                            desc={g["desc"]}
                                            pick={g["id"]}
                                            onPick={lambda (v: str) { goal = v; }}
                                        />
                                    }}
                                </div>
                            </Field>
                            <Field>
                                <FieldLabel>
                                    {"What is your experience level?"}
                                </FieldLabel>
                                <div className="grid gap-2 sm:grid-cols-3">
                                    {for lv in LEVELS {
                                        <OptionCard
                                            key={lv}
                                            selected={level == lv}
                                            title={lv.capitalize()}
                                            pick={lv}
                                            onPick={lambda (v: str) { level = v; }}
                                        />
                                    }}
                                </div>
                            </Field>
                        </div>;
                    } elif step == 2 {
                        <div className="flex flex-col gap-5">
                            <div className="flex flex-col gap-1.5">
                                <h1 className="text-2xl font-semibold tracking-tight">
                                    How often do you want to train?
                                </h1>
                                <p className="text-sm text-muted-foreground">
                                    We schedule the rest of the week as recovery days.
                                </p>
                            </div>
                            <Field>
                                <FieldLabel htmlFor="days">Days per week</FieldLabel>
                                <Input
                                    id="days"
                                    type="number"
                                    min="1"
                                    max="6"
                                    value={days_per_week}
                                    onChange={lambda (e: ChangeEvent) { days_per_week = e.target.value; }}
                                    className="h-10"
                                />
                            </Field>
                            <Field>
                                <FieldLabel>
                                    {"What equipment do you have access to?"}
                                </FieldLabel>
                                <div className="flex flex-wrap gap-2">
                                    {for eq in EQUIPMENT {
                                        <button
                                            key={eq}
                                            type="button"
                                            onClick={lambda (e: MouseEvent) { toggle(
                                                "equipment", eq
                                            ); }}
                                            className={cn(
                                                "rounded-full border px-3 py-1.5 text-sm shadow-sm transition-colors",
                                                eq in equipment
                                                    and "border-primary bg-primary text-primary-foreground",
                                            )}
                                        >
                                            {eq.replace("_", " ")}
                                        </button>
                                    }}
                                </div>
                            </Field>
                        </div>;
                    } elif step == 3 {
                        <div className="flex flex-col gap-5">
                            <div className="flex flex-col gap-1.5">
                                <h1 className="text-2xl font-semibold tracking-tight">
                                    What is your daily calorie target?
                                </h1>
                                <p className="text-sm text-muted-foreground">
                                    Choose your own target. Stride does not calculate calorie needs or a deficit.
                                </p>
                            </div>
                            <Field>
                                <FieldLabel>{"Dietary preference"}</FieldLabel>
                                <Select
                                    value={diet}
                                    onValueChange={lambda (v: str) { diet = v; }}
                                >
                                    <SelectTrigger className="w-full">
                                        <SelectValue placeholder="Choose a diet"/>
                                    </SelectTrigger>
                                    <SelectContent>
                                        {for d in DIETS {
                                            <SelectItem key={d["id"]} value={d["id"]}>
                                                {d["label"]}
                                            </SelectItem>
                                        }}
                                    </SelectContent>
                                </Select>
                            </Field>
                            <Field>
                                <FieldLabel htmlFor="calories">
                                    Daily calorie target (kcal)
                                </FieldLabel>
                                <Input
                                    id="calories"
                                    type="number"
                                    value={calorie_target}
                                    onChange={lambda (e: ChangeEvent) { calorie_target = e.target.value; }}
                                    className="h-10"
                                />
                            </Field>
                        </div>;
                    } else {
                        <div className="flex flex-col gap-5">
                            <div className="flex flex-col gap-1.5">
                                <h1 className="text-2xl font-semibold tracking-tight">
                                    Health and data
                                </h1>
                                <p className="text-sm text-muted-foreground">
                                    Optional notes stay in your account. The rule-based planner does not interpret injuries or health conditions.
                                </p>
                            </div>
                            <Field>
                                <FieldLabel htmlFor="conditions">
                                    Health conditions or injuries (optional)
                                </FieldLabel>
                                <Input
                                    id="conditions"
                                    placeholder="e.g. knee injury, asthma"
                                    value={health_conditions}
                                    onChange={lambda (e: ChangeEvent) { health_conditions = e.target.value; }}
                                    className="h-10"
                                />
                            </Field>
                            <Field>
                                <FieldLabel>
                                    {"Save my profile and activity to my account"}
                                </FieldLabel>
                                <div
                                    className="flex items-center gap-3 rounded-xl border bg-background px-4 py-3"
                                >
                                    <Switch
                                        checked={store_data}
                                        onCheckedChange={lambda (checked: any) { store_data = checked as bool; }}
                                    />
                                    <span className="text-sm text-muted-foreground">
                                        Required for account plans. Save my profile, logs, feedback and imported summaries on this server. Delete them from the Health tab any time.
                                    </span>
                                </div>
                            </Field>
                            <Field>
                                <FieldLabel>
                                    {"Health app interests (optional)"}
                                </FieldLabel>
                                <div className="flex flex-wrap gap-2">
                                    {for w in WEARABLES {
                                        <button
                                            key={w["id"]}
                                            type="button"
                                            onClick={lambda (e: MouseEvent) { toggle(
                                                "wearables", w["id"]
                                            ); }}
                                            className={cn(
                                                "flex items-center gap-2 rounded-full border px-3 py-1.5 text-sm shadow-sm transition-colors",
                                                w["id"] in wearables
                                                    and "border-primary bg-primary text-primary-foreground",
                                            )}
                                        >
                                            <HugeiconsIcon
                                                icon={CheckmarkCircle02Icon}
                                                strokeWidth={2}
                                                className="size-4"
                                            />
                                            {w["label"]}
                                        </button>
                                    }}
                                </div>
                                <p className="text-xs text-muted-foreground">
                                    These selections do not connect an app. Apple Health uses the iPhone companion from the Health tab. Oura, Fitbit and Garmin are planned.
                                </p>
                            </Field>
                        </div>;
                    }   }
                </div>
                {error
                    and <p role="alert" className="text-sm text-destructive">
                        {error}
                    </p>}
                <p className="text-xs text-muted-foreground">
                    Profile edits apply to the next generated week. Existing workouts and feedback stay saved.
                </p>
                <div className="flex items-center justify-between">
                    <Button
                        variant="outline"
                        onClick={lambda { if step > 1 { step = step - 1; }}}
                        disabled={step == 1}
                    >
                        <HugeiconsIcon
                            icon={ArrowLeft01Icon}
                            strokeWidth={2}
                            className="size-4"
                        />{" "}
                        Back
                    </Button>
                    {if step < total_steps {
                        <Button onClick={lambda { step = step + 1; }}>
                            Continue{" "}
                            <HugeiconsIcon
                                icon={ArrowRight01Icon}
                                strokeWidth={2}
                                className="size-4"
                            />
                        </Button>;
                    } else {
                        <Button
                            onClick={handle_finish}
                            disabled={saving or not store_data}
                        >
                            {saving and "Building your plan..."} {not saving
                                and "Finish and build my plan"}
                        </Button>;
                    } }
                </div>
            </div>
        </div>;
}
