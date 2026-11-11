import from services.nutrition { daily_food, analyze_food, log_food, set_consumed }
import from coach.coach_profile { CoachProfile, ProfileResult, validate_profile }
import from coach.coach_media { PhotoResult, prepare_photo }
import from coach.coach_provider { ProviderInfo, provider_info }
import from coach.coach_vision { PhotoObservation, analyze_photo }
import from coach.coach_goals { GoalDraft, GoalReply, refine_goal }
import ".coach.styles.css";
import from services.offline { offline_snapshot, sync_offline_change }
import from .components.OfflineApp { OfflineApp }
import from .components.OfflineSetup { OfflineSetup }
import from services.food_lookup { lookup_food }
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
    preview_next_week,
    get_plan_state,
    set_weekly_goal,
    get_activity_summary,
    save_health_summary,
    get_health_summary,
    get_movement_break,
    clear_account_data,
    ask_coach,
    coach_available,
    Profile,
    PlanDay,
    DailyLog,
    FriendView,
}

import "./styles/global.css";
import from "@jac/runtime" { Router, Routes, Route, AuthGuard }
import from .components.Landing { Landing }
import from .components.LoginPage { LoginPage }
import from .components.OnboardingWizard { OnboardingWizard }
import from .components.DashboardApp { DashboardApp }

def:pub app() -> JsxElement {
    return
        <Router>
            <link rel="manifest" href="/static/assets/manifest.webmanifest"/>
            <link rel="apple-touch-icon" href="/static/assets/mobile-icon-192.png"/>
            <meta name="apple-mobile-web-app-capable" content="yes"/>
            <meta name="apple-mobile-web-app-title" content="Stride"/>
            <OfflineSetup/>
            <Routes>
                <Route path="/offline" element={<OfflineApp/>}/>
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
