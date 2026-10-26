import from "@jac/runtime" { Link, useNavigate, jacLogout }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    DashboardSquare01Icon,
    PlusSignIcon,
    Settings01Icon,
    Logout01Icon
}
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.input { Input }
import from .ui.field { Field, FieldLabel }
import from .ui.badge { Badge }
import from .ui.tabs { Tabs, TabsList, TabsTrigger, TabsContent }
import from .ui.dialog {
    Dialog,
    DialogTrigger,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogFooter
}
import from .ui.progress { Progress }
import from ..services.stride {
    Profile,
    PlanDay,
    DailyLog,
    get_profile,
    get_plan,
    get_logs,
    give_feedback,
    save_log,
    meal_plan,
    regenerate_plan,
    get_plan_state,
    set_weekly_goal,
    get_activity_summary,
    save_health_summary,
    get_health_summary,
    get_movement_break,
    clear_account_data
}
import from ..health_panel { AppleHealthSync }
import from .ManualAverages { ManualAverages }
import from .ChatCoach { ChatCoach }
import from ..pdf_export { download_plan_pdf }

# All date comparisons and week totals use this browser-local calendar date.
def local_today() -> str {
    d = new(Date);
    mm = str(d.getMonth() + 1);
    dd = str(d.getDate());
    if len(mm) < 2 {
        mm = "0" + mm;
    }
    if len(dd) < 2 {
        dd = "0" + dd;
    }
    return str(d.getFullYear()) + "-" + mm + "-" + dd;
}

def:pub DashboardApp() -> JsxElement {
    has profile: Profile | None = None;
    has plan: list[PlanDay] = [],
        logs: list[DailyLog] = [];
    has meals: list[dict[str, any]] = [];
    has activity: dict[str, any] = {},
        health: dict[str, any] = {},
        plan_state: dict[str, any] = {},
        snack: dict[str, any] = {};
    has loading: bool = True,
        busy: bool = False,
        log_open: bool = False;
    has tab: str = "today",
        message: str = "",
        goal: str = "150",
        sitting: str = "60";
    has log_date: str = "",
        log_steps: str = "0",
        log_calories: str = "0",
        log_miles: str = "0",
        log_minutes: str = "0";
    nav = useNavigate();

    async def refresh() {
        profile = await get_profile();
        if profile is not None {
            plan = await get_plan();
            logs = await get_logs();
            plan_state = await get_plan_state();
            activity = await get_activity_summary(local_today());
            health = await get_health_summary();
            meals = await meal_plan();
            goal = str(profile.weekly_minutes_goal);
        }
    }

    async can with entry {
        try {
            await refresh();
        } except Exception {
            message = "Could not load your account. Reload or sign in again.";
        } finally {
            loading = False;
            log_date = local_today();
        }
    }

    async def handle_feedback(day_id: str, rating: str) {
        if busy {
            return;
        }
        busy = True;
        try {
            plan = await give_feedback(day_id, rating);
            plan_state = await get_plan_state();
            message = "Workout logged. Only later unlogged workouts of the same type may change.";
        } except Exception {
            message = "Could not save feedback. This workout may already be logged.";
        } finally {
            busy = False;
        }
    }

    def edit_log(stamp: str) {
        log_date = stamp;
        log_steps = "0";
        log_calories = "0";
        log_miles = "0";
        log_minutes = "0";
        for l in logs {
            if l.date == stamp {
                log_steps = str(l.steps);
                log_calories = str(l.calories_burned);
                log_miles = str(l.run_miles);
                log_minutes = str(l.active_minutes);
            }
        }
        log_open = True;
    }

    async def handle_save_log() {
        if busy {
            return;
        }
        busy = True;
        try {
            if not log_steps.isdigit()
                or not log_calories.isdigit()
                or not log_minutes.isdigit()
                or not log_miles.replace(".", "", 1).isdigit() {
                message = "Enter nonnegative numbers in every activity field.";
                return;
            }
            await save_log(
                log_date,
                int(log_steps),
                int(log_calories),
                float(log_miles),
                int(log_minutes),
                local_today()
            );
            logs = await get_logs();
            activity = await get_activity_summary(local_today());
            log_open = False;
            message = "Daily totals saved. Saving the same date replaces its totals.";
        } except Exception {
            message = "Could not save. Use a valid date through today, steps 0–100000, calories 0–20000, miles 0–200 and minutes 0–1440.";
        } finally {
            busy = False;
        }
    }

    async def handle_goal() {
        if busy {
            return;
        }
        busy = True;
        try {
            if not goal.isdigit() {
                message = "Enter a whole-number goal.";
                return;
            }
            await set_weekly_goal(int(goal));
            activity = await get_activity_summary(local_today());
            message = "Weekly activity goal saved.";
        } except Exception {
            message = "Choose a goal between 1 and 10080 minutes per week.";
        } finally {
            busy = False;
        }
    }

    async def next_week() {
        if busy
            or not window.confirm(
                "Archive this week and create the next week? Your workout history will be kept."
            ) {
            return;
        }
        busy = True;
        try {
            plan = await regenerate_plan();
            plan_state = await get_plan_state();
            meals = await meal_plan();
            message = "Next week ready. Previous workouts are in History.";
        } except Exception {
            message = "Could not create the next week. Your current plan is still saved.";
        } finally {
            busy = False;
        }
    }

    async def imported(summary: dict[str, any]) {
        try {
            health = await save_health_summary(summary);
            message = "Apple Health · 28-day summary saved. Unavailable metrics remain blank.";
        } except Exception {
            message = "Could not save the imported averages. Try syncing again.";
        }
    }

    async def break_suggestion() {
        try {
            if not sitting.isdigit() {
                message = "Enter sitting time as whole minutes.";
                return;
            }
            snack = await get_movement_break(int(sitting));
        } except Exception {
            message = "Enter sitting time between 0 and 1440 minutes.";
        }
    }

    async def export_pdf() {
        try {
            download_plan_pdf(plan_state);
            message = "Your plan PDF download has started.";
        } except Exception {
            message = "Could not export the PDF. Reload your saved plan and retry.";
        }
    }

    async def clear_data() {
        if busy
            or not window.confirm(
                "Delete your saved profile, plan history, activity logs and health summary? Your sign-in account will remain."
            ) {
            return;
        }
        busy = True;
        try {
            await clear_account_data();
            nav("/onboarding");
        } except Exception {
            message = "Could not delete saved data. Try again.";
        } finally {
            busy = False;
        }
    }

    today: PlanDay | None = None;
    for d in plan {
        if d.date == local_today() {
            today = d;
        }
    }
    p = profile;
    if loading {
        return
            <div className="min-h-svh flex items-center justify-center">
                Loading your plan…
            </div>;
    }
    if p is None {
        return
            <main className="mx-auto max-w-2xl px-6 py-24 text-center">
                <h1 className="text-2xl font-semibold">Welcome to Stride</h1>
                <p role="status">{message}</p>
                <Link to="/onboarding">
                    <Button>Start onboarding</Button>
                </Link>
            </main>;
    }

    return
        <div className="min-h-svh bg-muted/40">
            <header
                className="sticky top-0 z-20 border-b bg-background/90 backdrop-blur"
            >
                <div
                    className="mx-auto flex min-h-16 max-w-6xl flex-wrap items-center gap-3 px-4 py-3 sm:px-6"
                >
                    <Link to="/app" className="flex items-center gap-2 font-semibold">
                        <HugeiconsIcon
                            icon={DashboardSquare01Icon}
                            className="size-6 text-primary"
                        />
                        Stride
                    </Link>
                    <span className="text-sm text-muted-foreground">{p.name}</span>
                    <div className="ml-auto flex flex-wrap gap-2">
                        <Link to="/onboarding">
                            <Button variant="outline" size="sm">
                                <HugeiconsIcon
                                    icon={Settings01Icon}
                                    className="size-4"
                                />
                                Edit profile
                            </Button>
                        </Link>
                        <Button size="sm" onClick={lambda { edit_log(local_today()); }}>
                            <HugeiconsIcon icon={PlusSignIcon} className="size-4"/>
                            Log activity
                        </Button>
                        <Button
                            variant="ghost"
                            size="sm"
                            onClick={lambda {
                                jacLogout();
                                nav("/login");
                            }}
                        >
                            <HugeiconsIcon icon={Logout01Icon} className="size-4"/>
                            Log out
                        </Button>
                    </div>
                </div>
            </header>
            <main className="mx-auto flex max-w-6xl flex-col gap-6 px-4 py-8 sm:px-6">
                <div className="flex flex-wrap items-end justify-between gap-4">
                    <div>
                        <h1 className="text-2xl font-semibold tracking-tight">
                            Your week at a glance
                        </h1>
                        <p className="text-sm text-muted-foreground">
                            {str(p.days_per_week)
                                + " workouts per week · "
                                + str(p.calorie_target)
                                + " kcal daily target · "
                                + p.diet.replace("_", " ")}
                        </p>
                    </div>
                    <Badge variant="secondary">
                        {p.goal.replace("_", " ").capitalize()}
                    </Badge>
                </div>
                {message
                    and <p
                        className="rounded-lg border bg-background p-3 text-sm"
                        role="status"
                        aria-live="polite"
                    >
                        {message}
                    </p>}
                <Tabs value={tab} onValueChange={lambda (v: str) { tab = v; }}>
                    <TabsList className="flex flex-wrap h-auto">
                        <TabsTrigger value="today">Today</TabsTrigger>
                        <TabsTrigger value="coach">Coach</TabsTrigger>
                        <TabsTrigger value="plan">Plan</TabsTrigger>
                        <TabsTrigger value="meals">Meals</TabsTrigger>
                        <TabsTrigger value="progress">Progress</TabsTrigger>
                        <TabsTrigger value="health">Health</TabsTrigger>
                        <TabsTrigger value="history">History</TabsTrigger>
                    </TabsList>
                    <TabsContent value="coach" className="pt-2">
                        <Card>
                            <CardContent className="pt-6">
                                <ChatCoach/>
                            </CardContent>
                        </Card>
                    </TabsContent>
                    <TabsContent value="today" className="flex flex-col gap-6 pt-2">
                        <div className="grid gap-6 md:grid-cols-2">
                            <Card>
                                <CardHeader>
                                    <CardTitle>Today's activity</CardTitle>
                                    <CardDescription>
                                        {local_today() + " · manually logged totals"}
                                    </CardDescription>
                                </CardHeader>
                                <CardContent className="flex flex-col gap-3">
                                    {if activity.get("logged_today") {
                                        <p className="text-2xl font-semibold">
                                            {str(activity["active_minutes"])
                                                + " active minutes"}
                                        </p>
                                        <p className="text-sm text-muted-foreground">
                                            {str(activity["steps"])
                                                + " steps · "
                                                + str(activity["calories_burned"])
                                                + " kcal · "
                                                + str(activity["run_miles"])
                                                + " miles"}
                                        </p>
                                    } else {
                                        <p>No activity logged for today yet.</p>
                                    } }
                                    <Button
                                        variant="outline"
                                        onClick={lambda { edit_log(local_today()); }}
                                    >
                                        Update today's totals
                                    </Button>
                                </CardContent>
                            </Card>
                            <Card>
                                <CardHeader>
                                    <CardTitle>Weekly activity goal</CardTitle>
                                    <CardDescription>
                                        {"Week of "
                                            + str(activity.get("week_start", ""))
                                            + " · your chosen goal"}
                                    </CardDescription>
                                </CardHeader>
                                <CardContent className="flex flex-col gap-3">
                                    <p className="text-2xl font-semibold">
                                        {str(activity.get("weekly_minutes", 0))
                                            + " / "
                                            + str(activity.get("goal", 150))
                                            + " min"}
                                    </p>
                                    <Progress value={activity.get("percent", 0)}/>
                                    <p className="text-sm text-muted-foreground">
                                        {str(activity.get("remaining", 0))
                                            + " minutes remaining. Progress includes logged active minutes only."}
                                    </p>
                                    <Field>
                                        <FieldLabel htmlFor="weekly-goal">
                                            Goal in minutes per week
                                        </FieldLabel>
                                        <Input
                                            id="weekly-goal"
                                            type="number"
                                            min="1"
                                            max="10080"
                                            value={goal}
                                            onChange={lambda (e: any) { goal = e.target.value; }}
                                        />
                                    </Field>
                                    <Button
                                        variant="outline"
                                        disabled={busy}
                                        onClick={handle_goal}
                                    >
                                        Save weekly goal
                                    </Button>
                                </CardContent>
                            </Card>
                        </div>
                        <Card>
                            <CardHeader>
                                <CardTitle>
                                    {today.title
                                        if today is not None
                                        else "No session in your saved plan for today"}
                                </CardTitle>
                                <CardDescription>
                                    {today.date
                                        if today is not None
                                        else "Check the Plan tab for your scheduled week."}
                                </CardDescription>
                            </CardHeader>
                            <CardContent className="flex flex-col gap-3">
                                {if today is not None {
                                    for e in today.exercises {
                                        <a
                                            key={e["name"]}
                                            className="text-sm text-primary underline"
                                            href={"https://www.youtube.com/results?search_query="
                                                + encodeURIComponent(
                                                    e["name"] + " exercise tutorial"
                                                )}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                        >
                                            {e["name"]
                                                + " · "
                                                + (
                                                    str(e.get("duration")) + " min"
                                                        if e.get("duration")
                                                        else str(e["sets"])
                                                            + " × "
                                                            + str(e["reps"])
                                                )
                                                + " ↗"}
                                        </a>
                                    }
                                    if today.is_rest {
                                        <p>
                                            Rest and recover. Optional gentle stretching if it feels good.
                                        </p>
                                    } elif today.feedback {
                                        <Badge variant="secondary">
                                            Workout logged
                                        </Badge>
                                    } else {
                                        <p className="text-sm text-muted-foreground">
                                            How did your workout feel?
                                        </p>
                                        <div className="flex flex-wrap gap-2">
                                            <Button
                                                variant="outline"
                                                disabled={busy}
                                                onClick={lambda { handle_feedback(
                                                    str((today as PlanDay).order),
                                                    "too_easy"
                                                ); }}
                                            >
                                                Too easy
                                            </Button>
                                            <Button
                                                variant="outline"
                                                disabled={busy}
                                                onClick={lambda { handle_feedback(
                                                    str((today as PlanDay).order),
                                                    "just_right"
                                                ); }}
                                            >
                                                Just right
                                            </Button>
                                            <Button
                                                variant="outline"
                                                disabled={busy}
                                                onClick={lambda { handle_feedback(
                                                    str((today as PlanDay).order),
                                                    "too_hard"
                                                ); }}
                                            >
                                                Too hard
                                            </Button>
                                        </div>
                                    }
                                }}
                            </CardContent>
                        </Card>
                        <Card>
                            <CardHeader>
                                <CardTitle>A little room to move</CardTitle>
                                <CardDescription>
                                    An optional break based on sitting time you enter.
                                </CardDescription>
                            </CardHeader>
                            <CardContent className="flex flex-col gap-3">
                                <Field>
                                    <FieldLabel htmlFor="sitting">
                                        Minutes sitting since your last break
                                    </FieldLabel>
                                    <Input
                                        id="sitting"
                                        type="number"
                                        min="0"
                                        max="1440"
                                        value={sitting}
                                        onChange={lambda (e: any) { sitting = e.target.value; }}
                                    />
                                </Field>
                                <Button variant="outline" onClick={break_suggestion}>
                                    Suggest a movement break
                                </Button>
                                {if snack {
                                    if snack["suggested"] {
                                        <h3 className="font-medium">
                                            {snack["title"]}
                                        </h3>
                                        for line in snack["steps"] {
                                            <p key={line} className="text-sm">{line}</p>
                                        }
                                    } else {
                                        <p className="text-sm">
                                            No break reminder based on this entry. Move whenever it feels comfortable.
                                        </p>
                                    }
                                    <p className="text-xs text-muted-foreground">
                                        {snack["note"]}
                                    </p>
                                }}
                            </CardContent>
                        </Card>
                    </TabsContent>
                    <TabsContent value="plan" className="flex flex-col gap-4 pt-2">
                        <div
                            className="flex flex-wrap items-center justify-between gap-3"
                        >
                            <h2 className="text-lg font-semibold">
                                {"Week of " + str(plan_state.get("start_date", ""))}
                            </h2>
                            <div className="flex gap-2">
                                <Button
                                    variant="outline"
                                    disabled={busy}
                                    onClick={export_pdf}
                                >
                                    Download PDF
                                </Button>
                                <Button
                                    variant="outline"
                                    disabled={busy}
                                    onClick={next_week}
                                >
                                    Create next week
                                </Button>
                            </div>
                        </div>
                        <p className="text-sm text-muted-foreground">
                            {plan_state.get("memory_note", "")}
                        </p>
                        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                            {for d in plan {
                                <Card key={d.date}>
                                    <CardHeader>
                                        <div
                                            className="flex items-center justify-between"
                                        >
                                            <CardTitle className="text-base">
                                                {d.day}
                                            </CardTitle>
                                            <Badge variant="secondary">
                                                {"Rest"
                                                    if d.is_rest
                                                    else (
                                                        "Logged"
                                                            if d.feedback
                                                            else "Workout"
                                                    )}
                                            </Badge>
                                        </div>
                                        <CardDescription>
                                            {d.date + " · " + d.title}
                                        </CardDescription>
                                    </CardHeader>
                                    <CardContent className="flex flex-col gap-3">
                                        {for (i, e) in enumerate(d.exercises) {
                                            <a
                                                key={e["name"]}
                                                className="text-sm text-primary underline"
                                                target="_blank"
                                                rel="noopener noreferrer"
                                                href={"https://www.youtube.com/results?search_query="
                                                    + encodeURIComponent(
                                                        e["name"] + " exercise tutorial"
                                                    )}
                                            >
                                                {d.details[i] + " ↗"}
                                            </a>
                                        }}
                                        {if not d.is_rest
                                            and not d.feedback
                                            and d.date <= local_today() {
                                            <div className="flex flex-wrap gap-1">
                                                <Button
                                                    size="sm"
                                                    variant="outline"
                                                    disabled={busy}
                                                    onClick={lambda { handle_feedback(
                                                        str(d.order), "too_easy"
                                                    ); }}
                                                >
                                                    Too easy
                                                </Button>
                                                <Button
                                                    size="sm"
                                                    variant="outline"
                                                    disabled={busy}
                                                    onClick={lambda { handle_feedback(
                                                        str(d.order), "just_right"
                                                    ); }}
                                                >
                                                    Just right
                                                </Button>
                                                <Button
                                                    size="sm"
                                                    variant="outline"
                                                    disabled={busy}
                                                    onClick={lambda { handle_feedback(
                                                        str(d.order), "too_hard"
                                                    ); }}
                                                >
                                                    Too hard
                                                </Button>
                                            </div>
                                        }}
                                        {d.is_rest
                                            and <p
                                                className="text-sm text-muted-foreground"
                                            >
                                                Take the day off. Optional gentle stretching.
                                            </p>}
                                    </CardContent>
                                </Card>
                            }}
                        </div>
                    </TabsContent>
                    <TabsContent value="meals" className="flex flex-col gap-4 pt-2">
                        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                            {for m in meals {
                                <Card key={m["name"]}>
                                    <CardHeader>
                                        <CardDescription>{m["meal"]}</CardDescription>
                                        <CardTitle className="text-lg">
                                            {m["name"]}
                                        </CardTitle>
                                    </CardHeader>
                                    <CardContent className="flex flex-col gap-3">
                                        <a
                                            href={m["video"]["url"]}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                            className="block overflow-hidden rounded-lg border"
                                            aria-label={"Watch recipe video for "
                                                + m["name"]}
                                        >
                                            <img
                                                className="aspect-video w-full object-cover"
                                                src={m["video"]["fallback"]}
                                                alt={"Recipe video: " + m["name"]}
                                                loading="lazy"
                                            />
                                            <span
                                                className="block p-2 text-sm text-primary"
                                            >
                                                Watch recipe video ↗
                                            </span>
                                        </a>
                                        <p className="text-sm text-muted-foreground">
                                            {m["detail"]}
                                        </p>
                                        <strong>
                                            {"≈ "
                                                + str(m["calories"])
                                                + " kcal per serving"}
                                        </strong>
                                    </CardContent>
                                </Card>
                            }}
                        </div>
                        <p className="text-sm text-muted-foreground">
                            Meal ideas are examples, not a complete daily menu. They do not add up to your user-entered calorie target. Recipe videos may use different portions or ingredients.
                        </p>
                    </TabsContent>
                    <TabsContent value="progress" className="flex flex-col gap-4 pt-2">
                        <Card>
                            <CardHeader>
                                <CardTitle>
                                    {str(activity.get("streak", 0))
                                        + " day activity streak"}
                                </CardTitle>
                                <CardDescription>
                                    Consecutive dates with recorded activity, ending today or yesterday.
                                </CardDescription>
                            </CardHeader>
                            <CardContent className="overflow-x-auto">
                                {if not logs {
                                    <p>No activity logged yet.</p>
                                } else {
                                    <table className="w-full text-left text-sm">
                                        <thead>
                                            <tr>
                                                <th className="p-3">Date</th>
                                                <th>Steps</th>
                                                <th>Active min</th>
                                                <th>kcal</th>
                                                <th>Miles</th>
                                                <th>Edit</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {for l in logs {
                                                <tr key={l.date} className="border-t">
                                                    <td className="p-3">{l.date}</td>
                                                    <td>{l.steps}</td>
                                                    <td>{l.active_minutes}</td>
                                                    <td>{l.calories_burned}</td>
                                                    <td>{l.run_miles}</td>
                                                    <td>
                                                        <Button
                                                            size="sm"
                                                            variant="ghost"
                                                            onClick={lambda { edit_log(
                                                                l.date
                                                            ); }}
                                                        >
                                                            Edit totals
                                                        </Button>
                                                    </td>
                                                </tr>
                                            }}
                                        </tbody>
                                    </table>
                                } }
                            </CardContent>
                        </Card>
                    </TabsContent>
                    <TabsContent value="health" className="flex flex-col gap-4 pt-2">
                        <Card>
                            <CardHeader>
                                <CardTitle>Apple Health</CardTitle>
                                <CardDescription>
                                    28-day averages from the Stride Health iOS companion. Other wearable connections are planned.
                                </CardDescription>
                            </CardHeader>
                            <CardContent className="flex flex-col gap-4">
                                <AppleHealthSync onSynced={imported}/>
                                {if health {
                                    <h3 className="font-medium">{health["source"]}</h3>
                                    <p className="text-sm">
                                        {"Daily steps: "
                                            + str(
                                                health.get("avg_daily_steps")
                                                    if health.get("avg_daily_steps")
                                                        is not None
                                                    else "Unavailable"
                                            )}
                                    </p>
                                    <p className="text-sm">
                                        {"Heart rate: "
                                            + str(
                                                health.get("avg_heart_rate")
                                                    if health.get("avg_heart_rate")
                                                        is not None
                                                    else "Unavailable"
                                            )}
                                    </p>
                                    <p className="text-sm">
                                        {"Sleep hours: "
                                            + str(
                                                health.get("avg_sleep_hours")
                                                    if health.get("avg_sleep_hours")
                                                        is not None
                                                    else "Unavailable"
                                            )}
                                    </p>
                                    <p className="text-sm">
                                        {"Workouts per week: "
                                            + str(
                                                health.get("avg_workouts_per_week")
                                                    if health.get(
                                                        "avg_workouts_per_week"
                                                    )
                                                        is not None
                                                    else "Unavailable"
                                            )}
                                    </p>
                                }}
                                <ManualAverages
                                    onSaved={lambda (value: dict[str, any]) { health = value; }}
                                />
                                <p className="text-sm text-muted-foreground">
                                    These averages are separate from daily activity logs. They do not determine readiness or change your calorie target.
                                </p>
                                <Button
                                    variant="outline"
                                    disabled={busy}
                                    onClick={clear_data}
                                >
                                    Delete saved Stride data
                                </Button>
                            </CardContent>
                        </Card>
                    </TabsContent>
                    <TabsContent value="history" className="flex flex-col gap-4 pt-2">
                        <h2 className="text-lg font-semibold">Previous weeks</h2>
                        {if not plan_state.get("history", []) {
                            <p className="text-sm text-muted-foreground">
                                Create your next week to archive this plan and its workout feedback.
                            </p>
                        }}
                        {for week in plan_state.get("history", []) {
                            <Card key={week["week_id"]}>
                                <CardHeader>
                                    <CardTitle>
                                        {"Week of " + week["start_date"]}
                                    </CardTitle>
                                </CardHeader>
                                <CardContent className="flex flex-col gap-2">
                                    {for day in week["plan"] {
                                        <div key={day["date"]} className="text-sm">
                                            <strong>
                                                {day["day"] + " · " + day["title"]}
                                            </strong>
                                            {for e in day["exercises"] {
                                                <p
                                                    key={e["name"]}
                                                    className="text-muted-foreground"
                                                >
                                                    {e["name"]
                                                        + " · "
                                                        + (
                                                            str(e.get("duration"))
                                                                + " min"
                                                                if e.get("duration")
                                                                else str(e["sets"])
                                                                    + " × "
                                                                    + str(e["reps"])
                                                        )}
                                                </p>
                                            }}
                                            <span>
                                                {"Feedback: "
                                                    + str(
                                                        week["feedback"].get(
                                                            str(day["index"]),
                                                            "Not logged"
                                                        )
                                                    )}
                                            </span>
                                        </div>
                                    }}
                                </CardContent>
                            </Card>
                        }}
                    </TabsContent>
                </Tabs>
            </main>
            <Dialog
                open={log_open}
                onOpenChange={lambda (o: any) { log_open = o as bool; }}
            >
                <DialogContent className="sm:max-w-md">
                    <DialogHeader>
                        <DialogTitle>Daily activity totals</DialogTitle>
                    </DialogHeader>
                    <div className="flex flex-col gap-3">
                        <p className="text-sm text-muted-foreground">
                            Enter totals for one date. Existing totals for that date will be replaced.
                        </p>
                        <Field>
                            <FieldLabel htmlFor="log-date">Date</FieldLabel>
                            <Input
                                id="log-date"
                                type="date"
                                max={local_today()}
                                value={log_date}
                                onChange={lambda (e: any) { log_date = e.target.value; }}
                            />
                        </Field>
                        <Field>
                            <FieldLabel htmlFor="log-steps">
                                Steps (0–100000)
                            </FieldLabel>
                            <Input
                                id="log-steps"
                                type="number"
                                min="0"
                                max="100000"
                                value={log_steps}
                                onChange={lambda (e: any) { log_steps = e.target.value; }}
                            />
                        </Field>
                        <Field>
                            <FieldLabel htmlFor="log-minutes">
                                Active minutes (0–1440)
                            </FieldLabel>
                            <Input
                                id="log-minutes"
                                type="number"
                                min="0"
                                max="1440"
                                value={log_minutes}
                                onChange={lambda (e: any) { log_minutes = e.target.value; }}
                            />
                        </Field>
                        <Field>
                            <FieldLabel htmlFor="log-calories">
                                Calories burned (0–20000)
                            </FieldLabel>
                            <Input
                                id="log-calories"
                                type="number"
                                min="0"
                                max="20000"
                                value={log_calories}
                                onChange={lambda (e: any) { log_calories = e.target.value; }}
                            />
                        </Field>
                        <Field>
                            <FieldLabel htmlFor="log-miles">
                                Run miles (0–200)
                            </FieldLabel>
                            <Input
                                id="log-miles"
                                type="number"
                                min="0"
                                max="200"
                                step="0.1"
                                value={log_miles}
                                onChange={lambda (e: any) { log_miles = e.target.value; }}
                            />
                        </Field>
                        {message and <p className="text-sm" role="status">{message}</p>}
                    </div>
                    <DialogFooter>
                        <Button
                            variant="outline"
                            disabled={busy}
                            onClick={lambda { log_open = False; }}
                        >
                            Cancel
                        </Button>
                        <Button disabled={busy} onClick={handle_save_log}>
                            {"Saving…" if busy else "Save totals"}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>;
}
