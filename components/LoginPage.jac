import from "@jac/runtime" { Link, useNavigate, jacLogin, jacSignup, SignupResult }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    DashboardSquare01Icon,
    Calendar03Icon,
    SparklesIcon,
    UserGroupIcon
}
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.field { Field, FieldLabel, FieldGroup }

def:pub LoginPage() -> JsxElement {
    has mode: str = "login";
    has email: str = "";
    has password: str = "";
    has busy: bool = False;
    has error: str = "";
    nav = useNavigate();

    async def handle_submit(e: any) {
        e.preventDefault();
        busy = True;
        error = "";
        if mode == "signup" {
            signup_result: SignupResult | None = None;
            login_ok: bool = False;
            try {
                signup_result = await jacSignup(email, password);
                if not signup_result.success {
                    error = "Could not create the account - that email may already be in use.";
                    busy = False;
                    return;
                }
                login_ok = await jacLogin(email, password);
                if not login_ok {
                    error = "Account created, but sign-in failed. Try logging in.";
                    busy = False;
                    return;
                }
            } except Exception {
                error = "Something went wrong during signup.";
                busy = False;
                return;
            }
            nav("/onboarding");
        } else {
            login_ok: bool = False;
            try {
                login_ok = await jacLogin(email, password);
                if not login_ok {
                    error = "Invalid email or password.";
                    busy = False;
                    return;
                }
            } except Exception {
                error = "Something went wrong during sign-in.";
                busy = False;
                return;
            }
            nav("/app");
        }
    }

    return
        <div className="grid min-h-svh lg:grid-cols-2">
            <div
                className="relative hidden overflow-hidden bg-primary text-primary-foreground lg:flex lg:flex-col lg:justify-between pt-10 pb-10 pl-10 pr-10"
            >
                <div
                    className="pointer-events-none absolute -right-24 -top-24 size-96 rounded-full bg-primary-foreground/10 blur-3xl"
                />
                <div
                    className="pointer-events-none absolute -bottom-32 -left-16 size-96 rounded-full bg-primary-foreground/10 blur-3xl"
                />
                <div className="relative flex items-center gap-2.5">
                    <div
                        className="flex size-8 items-center justify-center rounded-lg bg-primary-foreground/15 ring-1 ring-primary-foreground/20"
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
                <div className="relative flex max-w-md flex-col gap-8">
                    <h1
                        className="text-balance text-4xl font-semibold leading-tight tracking-tight"
                    >
                        {"Your plan, your pace, your progress."}
                    </h1>
                    <div className="flex flex-col gap-4">
                        <div className="flex items-start gap-3">
                            <div
                                className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary-foreground/15"
                            >
                                <HugeiconsIcon
                                    icon={Calendar03Icon}
                                    strokeWidth={2}
                                    className="size-4"
                                />
                            </div>
                            <div>
                                <p className="font-medium">
                                    {"A plan that adapts to you"}
                                </p>
                                <p className="text-sm text-primary-foreground/75">
                                    {"Weekly workouts tuned by how each session felt."}
                                </p>
                            </div>
                        </div>
                        <div className="flex items-start gap-3">
                            <div
                                className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary-foreground/15"
                            >
                                <HugeiconsIcon
                                    icon={SparklesIcon}
                                    strokeWidth={2}
                                    className="size-4"
                                />
                            </div>
                            <div>
                                <p className="font-medium">{"Meals for your diet"}</p>
                                <p className="text-sm text-primary-foreground/75">
                                    {"Keto, vegetarian or high-protein - with calorie estimates."}
                                </p>
                            </div>
                        </div>
                        <div className="flex items-start gap-3">
                            <div
                                className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary-foreground/15"
                            >
                                <HugeiconsIcon
                                    icon={UserGroupIcon}
                                    strokeWidth={2}
                                    className="size-4"
                                />
                            </div>
                            <div>
                                <p className="font-medium">{"Track your activity"}</p>
                                <p className="text-sm text-primary-foreground/75">
                                    {"Daily totals and a weekly goal you choose."}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
                <p className="relative text-sm text-primary-foreground/80">
                    {"Your profile and activity stay in your own account."}
                </p>
            </div>
            <div
                className="flex flex-col bg-background pt-8 pb-8 pl-6 pr-6 sm:pl-10 sm:pr-10"
            >
                <div className="lg:hidden">
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
                </div>
                <div className="flex flex-1 items-center justify-center">
                    <form
                        onSubmit={handle_submit}
                        className="flex w-full max-w-sm flex-col gap-6 animate-in fade-in slide-in-from-bottom-2 duration-500"
                    >
                        <div className="flex flex-col gap-1.5">
                            <h2 className="text-2xl font-semibold tracking-tight">
                                {mode == "login"
                                    and "Welcome back"
                                    or "Create your account"}
                            </h2>
                            <p className="text-sm text-muted-foreground">
                                {mode == "login"
                                    and "Sign in to see your plan and streak."
                                    or "Two minutes of setup and your first weekly plan is built."}
                            </p>
                        </div>
                        <FieldGroup>
                            <Field>
                                <FieldLabel htmlFor="email">Email</FieldLabel>
                                <Input
                                    id="email"
                                    type="email"
                                    placeholder="you@example.com"
                                    value={email}
                                    onChange={lambda (e: ChangeEvent) { email = e.target.value; }}
                                    className="h-10"
                                />
                            </Field>
                            <Field>
                                <FieldLabel htmlFor="password">Password</FieldLabel>
                                <Input
                                    id="password"
                                    type="password"
                                    placeholder="At least 6 characters"
                                    value={password}
                                    onChange={lambda (e: ChangeEvent) { password = e.target.value; }}
                                    className="h-10"
                                />
                            </Field>
                        </FieldGroup>
                        {error != ""
                            and <p className="text-sm text-destructive">{error}</p>}
                        <Button type="submit" disabled={busy} className="h-10 w-full">
                            {busy and "Please wait..."}{not busy
                                and (mode == "login" and "Sign in" or "Create account")}
                        </Button>
                        <p className="text-center text-sm text-muted-foreground">
                            {mode == "login"
                                and "New to Stride? "
                                or "Already have an account? "}
                            <button
                                type="button"
                                onClick={lambda {
                                    error = "";
                                    mode = "signup" if mode == "login" else "login";
                                }}
                                className="font-medium text-foreground underline-offset-4 hover:underline"
                            >
                                {mode == "login" and "Create an account" or "Sign in"}
                            </button>
                        </p>
                        <p className="text-center text-xs text-muted-foreground">
                            {"Just looking around? "}
                            <Link
                                to="/"
                                className="font-medium text-foreground underline-offset-4 hover:underline"
                            >
                                Back to the home page
                            </Link>
                        </p>
                    </form>
                </div>
            </div>
        </div>;
}
