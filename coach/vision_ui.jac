import from "react" { useEffect }
import from .coach_provider { ProviderInfo, provider_info }
import from .coach_vision { PhotoObservation, analyze_photo }

def:pub VisionPanel(photo: str, onFocus: Callable[[str], None]) -> JsxElement {
    has provider: ProviderInfo = ProviderInfo(), observation: PhotoObservation = PhotoObservation(),
        consent: bool = False, busy: bool = False, chosen: str = "", attempted: bool = False;
    has alive: Ref[bool] = Ref(True), pending: Ref[bool] = Ref(False);
    useEffect(lambda { alive.current = True; return lambda { alive.current = False; }; }, []);
    can with entry { loadProvider(); }
    async def loadProvider() -> None {
        try { info = await provider_info(); if alive.current { provider = info; } }
        except Exception { if alive.current { provider = ProviderInfo(error="Cannot load provider settings."); } }
    }
    async def analyze() -> None {
        if pending.current or not provider.ready or (provider.external and not consent) { return; }
        pending.current = True;
        busy = True;
        attempted = True;
        chosen = "";
        observation = PhotoObservation();
        try {
            result = await analyze_photo(photo, provider.consent_id);
            if alive.current { observation = result; }
        } except Exception { if alive.current { observation = PhotoObservation(message="Analysis could not finish. Retry or choose a manual focus."); } }
        finally { if alive.current { busy = False; pending.current = False; } }
    }
    <section className="analysis-panel" aria-label="Photo observations">
        <h3>Current photo observations</h3>
        <p className="hint">Visible regions, framing and pose can inform your starting point. A photo cannot establish fitness, health, body fat or a healthy arm-to-leg ratio.</p>
        {if provider.ready {
            <p className="hint">{"API destination: " if provider.external else "Local model: "}{provider.destination} · {provider.vision_model}</p>
            if provider.external { <label className="consent"><input type="checkbox" checked={consent} onChange={lambda (e: ChangeEvent) { consent = e.target.checked; }}/>I agree to send this sanitized photo to {provider.destination} for analysis. Provider retention policies apply.</label> }
            <button type="button" disabled={busy or (provider.external and not consent)} onClick={analyze}>{"Analyzing…" if busy else "Analyze this photo"}</button>
        } else { <p role="status">{provider.error}</p> }}
        {if attempted and not busy {
            <p role="status">{observation.message}</p>
            if observation.status == "observed" {
                <dl><dt>Visible regions (tentative)</dt><dd>{", ".join(observation.regions)}</dd><dt>Image quality</dt><dd>{observation.quality}</dd><dt>Framing / pose</dt><dd>{observation.framing} / {observation.pose}</dd></dl>
                <label>Confirm an exercise focus<select value={chosen} onChange={lambda (e: ChangeEvent) { chosen = e.target.value; }}><option value="">Choose or correct below</option>{[<option key={region} value={region}>{region}</option> for region in observation.regions]}</select></label>
                <button type="button" disabled={not chosen} onClick={lambda { callback: any = onFocus; callback.call(None, chosen); }}>Use this focus</button>
                <p className="hint">You can choose any other region in Make it yours. Your selection always wins.</p>
            }
        }}
    </section>
}
