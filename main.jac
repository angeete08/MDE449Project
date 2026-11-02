import from health_sync {
    start_health_sync,
    health_sync_status,
    finish_health_sync,
    receive_health_batch,
    receive_health_log,
    release_health_sync
}
import from services.stride {
    save_profile,
    get_profile,
    get_plan,
    get_logs,
    get_scoreboard,
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
    clear_account_data,
    ask_coach,
    Profile,
    PlanDay,
    DailyLog,
    FriendView,
}

import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route, AuthGuard }
import from .components.Landing { Landing }
import from .components.LoginPage { LoginPage }
import from .components.OnboardingWizard { OnboardingWizard }
import from .components.DashboardApp { DashboardApp }

def:pub app() -> JsxElement {
    return
        <Router>
            <Routes>
                <Route path="/" element={<Landing/>}/>
                <Route path="/login" element={<LoginPage/>}/>
                <Route path="/mobile-login" element={<LoginPage mobile={True}/>}/>
                <Route element={<AuthGuard redirect="/login"/>}>
                    <Route path="/onboarding" element={<OnboardingWizard/>}/>
                    <Route path="/app" element={<DashboardApp/>}/>
                </Route>
                <Route element={<AuthGuard redirect="/mobile-login"/>}>
                    <Route path="/mobile-onboarding" element={<OnboardingWizard mobile={True}/>}/>
                    <Route path="/mobile" element={<DashboardApp mobile={True}/>}/>
                </Route>
            </Routes>
        </Router>;
}
