import from "@jac/runtime" { Link }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    DashboardSquare01Icon,
    Calendar03Icon,
    SparklesIcon,
    ArrowRight01Icon,
    CheckmarkCircle02Icon
}
import from .ui.button { Button }
import from .ui.badge { Badge }

glob FEATURES: list[dict[str, any]] = [
         {
             "icon": Calendar03Icon,
             "title": "Weekly workout plan",
             "desc": "A day-by-day schedule built from your goal, experience level and equipment - rest days included."
         },
         {
             "icon": DashboardSquare01Icon,
             "title": "A weekly goal you choose",
             "desc": "Log active minutes and track progress toward your own weekly goal."
         },
         {
             "icon": SparklesIcon,
             "title": "Meals for your diet",
             "desc": "Keto, vegetarian, high-protein or no restriction - suggested meals with estimated calories."
         },
         {
             "icon": CheckmarkCircle02Icon,
             "title": "Feedback that adjusts",
             "desc": "Too easy, just right, too hard - Stride tunes future workouts to how you actually felt."
         },

     ];

def:pub Landing() -> JsxElement {
    year = str(new(Date).getFullYear());
    return
        <div className="min-h-svh bg-muted/40">
            <nav className="sticky top-0 z-20 border-b bg-background/80 backdrop-blur">
                <div
                    className="mx-auto flex h-16 max-w-6xl items-center gap-8 pl-6 pr-6"
                >
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
                    <div className="hidden gap-6 text-sm text-muted-foreground md:flex">
                        <span>Plan</span>
                        <span>Meals</span>
                        <span>Progress</span>
                    </div>
                    <div className="ml-auto">
                        <Link to="/onboarding">
                            <Button className="shadow-sm">Get started</Button>
                        </Link>
                    </div>
                </div>
            </nav>
            <section className="relative overflow-hidden">
                <div
                    className="pointer-events-none absolute inset-0 bg-[radial-gradient(60%_50%_at_80%_20%,color-mix(in_oklch,var(--primary)_18%,transparent),transparent)]"
                />
                <div
                    className="mx-auto grid max-w-6xl items-center gap-12 pt-16 pb-16 pl-6 pr-6 lg:grid-cols-2 lg:pt-20 lg:pb-20"
                >
                    <div className="flex flex-col gap-6">
                        <Badge variant="secondary" className="w-fit">
                            Your personalized fitness coach
                        </Badge>
                        <h1
                            className="text-balance text-4xl font-semibold leading-[1.1] tracking-tight md:text-5xl"
                        >
                            A weekly plan that fits your body, your diet and your week.
                        </h1>
                        <p className="text-lg text-muted-foreground">
                            Stride builds weekly workouts and meal ideas from your profile, with tutorial videos and feedback that tunes future sessions.
                        </p>
                        <div className="flex flex-wrap gap-3">
                            <Link to="/onboarding">
                                <Button size="lg" className="shadow-sm">
                                    Build my plan{" "}
                                    <HugeiconsIcon
                                        icon={ArrowRight01Icon}
                                        strokeWidth={2}
                                        className="size-4"
                                    />
                                </Button>
                            </Link>
                            <Link to="/app">
                                <Button size="lg" variant="outline">
                                    Open my dashboard
                                </Button>
                            </Link>
                        </div>
                    </div>
                    <div className="relative">
                        <div
                            className="absolute -inset-4 rounded-3xl bg-primary/10 blur-2xl"
                        />
                        <div
                            className="relative rounded-2xl border bg-card p-5 shadow-xl"
                        >
                            <div className="flex items-center justify-between pb-3">
                                <span className="text-sm font-medium">
                                    Example week
                                </span>
                                <Badge>1,900 kcal target</Badge>
                            </div>
                            <div className="flex flex-col gap-2">
                                <div
                                    className="flex items-center justify-between rounded-lg border bg-background px-3 py-2.5"
                                >
                                    <span className="text-sm font-medium">Monday</span>
                                    <span className="text-sm text-muted-foreground">
                                        Strength - dumbbell squats
                                    </span>
                                </div>
                                <div
                                    className="flex items-center justify-between rounded-lg border bg-background px-3 py-2.5"
                                >
                                    <span className="text-sm font-medium">Tuesday</span>
                                    <span className="text-sm text-muted-foreground">
                                        Cardio - run 5k
                                    </span>
                                </div>
                                <div
                                    className="flex items-center justify-between rounded-lg border bg-background px-3 py-2.5 opacity-60"
                                >
                                    <span className="text-sm font-medium">
                                        Wednesday
                                    </span>
                                    <span className="text-sm text-muted-foreground">
                                        Rest and recover
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
            <section className="mx-auto max-w-6xl pt-8 pb-16 pl-6 pr-6">
                <div className="grid gap-4 md:grid-cols-2">
                    {for f in FEATURES {
                        <div
                            key={f["title"]}
                            className="flex flex-col gap-3 rounded-2xl border bg-card p-6 shadow-sm"
                        >
                            <div
                                className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"
                            >
                                <HugeiconsIcon
                                    icon={(f["icon"] as any)}
                                    strokeWidth={2}
                                    className="size-4"
                                />
                            </div>
                            <h3 className="text-lg font-semibold tracking-tight">
                                {f["title"]}
                            </h3>
                            <p className="text-sm text-muted-foreground">{f["desc"]}</p>
                        </div>
                    }}
                </div>
            </section>
            <footer className="border-t">
                <div
                    className="mx-auto flex max-w-6xl items-center justify-between pl-6 pr-6 py-6"
                >
                    <span className="text-sm font-medium">Stride</span>
                    <span className="text-sm text-muted-foreground">{"© " + year}</span>
                </div>
            </footer>
        </div>;
}
