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
                <Route element={<AuthGuard redirect="/login"/>}>
                    <Route path="/onboarding" element={<OnboardingWizard/>}/>
                    <Route path="/app" element={<DashboardApp/>}/>
                </Route>
            </Routes>
        </Router>;
}
