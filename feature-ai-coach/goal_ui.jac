import from "react" { useEffect }
import from .coach_provider { ProviderInfo, provider_info }
import from .coach_goals { GoalDraft, GoalReply, refine_goal }

def:pub GoalPicture(style: str, upper: int = 1, lower: int = 1) -> JsxElement {
    labels = {"general_strength": "Balanced strength & activity", "muscle": "Muscle-building direction", "lean_toned": "Strength & endurance direction", "fat_loss": "Whole-body activity direction"};
    <figure className="goal-picture">
        <svg viewBox="0 0 280 240" role="img" aria-label={str(labels[style]) + ". Upper-body emphasis " + str(upper) + ", lower-body emphasis " + str(lower) + ". Illustrative training focus, not a predicted body."}>
            <rect x="0" y="0" width="280" height="240" rx="18" fill="#edf3e7"/>
            <circle cx="140" cy="36" r="17" fill="#89988a"/>
            <path d="M140 66 L140 134 M106 72 L174 72 M106 72 L82 119 M174 72 L198 119" stroke="#d1dbcd" strokeWidth="18" strokeLinecap="round" fill="none"/>
            <path d="M140 137 L119 201 M140 137 L161 201" stroke="#d1dbcd" strokeWidth="20" strokeLinecap="round" fill="none"/>
            <path d="M140 66 L140 134 M106 72 L174 72 M106 72 L82 119 M174 72 L198 119" stroke="#315d42" strokeWidth="12" strokeLinecap="round" opacity={0.2 + upper * 0.25} fill="none"/>
            <path d="M140 137 L119 201 M140 137 L161 201" stroke="#a66a28" strokeWidth="14" strokeLinecap="round" opacity={0.2 + lower * 0.25} fill="none"/>
            <text x="16" y="225" fontSize="11" fill="#38523e">Upper {upper}/3 · Lower {lower}/3</text>
            {if style == "muscle" { <path d="M20 45 L60 45 M20 30 L20 60 M60 30 L60 60" stroke="#315d42" strokeWidth="6"/> }
            elif style == "fat_loss" { <path d="M18 45 L28 45 L35 25 L45 65 L53 45 L66 45" stroke="#315d42" strokeWidth="3" fill="none"/> }
            elif style == "lean_toned" { <path d="M20 35 Q40 10 60 35 M60 45 Q40 70 20 45" stroke="#315d42" strokeWidth="3" fill="none"/> }
            else { <circle cx="40" cy="45" r="20" stroke="#315d42" strokeWidth="3" fill="none"/> }}
        </svg>
        <figcaption><strong>{labels[style]}</strong><p className="hint">Example activity direction. Color shows requested emphasis, not body size or a promised transformation.</p></figcaption>
    </figure>
}

def:pub GoalStudio(goal: str, onUse: Callable[[str, str, int, int], None]) -> JsxElement {
    has provider: ProviderInfo = ProviderInfo(), consent: bool = False,
        draft: GoalDraft = GoalDraft(), message: str = "", transcript: list[str] = [],
        reply: str = "Describe what matters to you. Each refinement updates the example picture; you can also change the controls directly.",
        busy: bool = False, accepted: bool = False, description: str = "",
        selectedDraft: GoalDraft = GoalDraft(), selectedDescription: str = "";
    has dialog: Ref[any] = Ref(None), alive: Ref[bool] = Ref(True), revision: Ref[int] = Ref(0), pending: Ref[bool] = Ref(False);
    useEffect(lambda { alive.current = True; return lambda { alive.current = False; revision.current += 1; }; }, []);
    useEffect(lambda { if goal == "other" and dialog.current and not dialog.current.open { dialog.current.showModal(); } }, [goal]);
    can with entry { loadProvider(); }
    async def loadProvider() -> None {
        try { info = await provider_info(); if alive.current { provider = info; } }
        except Exception { if alive.current { provider = ProviderInfo(error="Provider unavailable; manual controls work."); } }
    }
    def update(style: str, upper: int, lower: int) -> None {
        revision.current += 1;
        draft = GoalDraft(style=style, upper=upper, lower=lower);
    }
    async def refine() -> None {
        if pending.current or not message.strip() or (provider.external and not consent) { return; }
        pending.current = True;
        busy = True;
        ticket = revision.current;
        request = message;
        transcript = (transcript + ["You: " + request])[-8:];
        message = "";
        try {
            result = await refine_goal(request, draft, provider.consent_id);
            if alive.current and ticket == revision.current {
                if result.status in ["ready", "clarify"] { draft = result.draft; description = request; }
                reply = result.message;
                transcript = (transcript + ["Coach: " + result.message])[-8:];
            }
        } except Exception { if alive.current and ticket == revision.current { reply = "The request failed. Adjust the controls manually or retry."; } }
        finally { if alive.current { busy = False; pending.current = False; } }
    }
    def close() -> None {
        revision.current += 1;
        draft = selectedDraft;
        description = selectedDescription;
        if dialog.current { dialog.current.close(); }
    }
    def accept() -> None {
        callback: any = onUse;
        callback.call(None, draft.style, description if description else "Custom activity direction", draft.upper, draft.lower);
        selectedDraft = draft;
        selectedDescription = description;
        accepted = True;
        revision.current += 1;
        if dialog.current { dialog.current.close(); }
    }
    <section aria-label="Goal picture examples">
        {if goal != "other" { <GoalPicture style={goal} upper={2 if goal == "muscle" else 1} lower={2 if goal == "muscle" else 1}/> }
        else {
            <GoalPicture style={selectedDraft.style} upper={selectedDraft.upper} lower={selectedDraft.lower}/>
            <p className="hint">{"Custom direction selected. Reopen to refine it." if accepted else "Customize and select Use this goal before confirming your preferences."}</p>
            <button type="button" onClick={lambda { if dialog.current { dialog.current.showModal(); } }}>Customize goal</button>
        }}
        <dialog ref={dialog} className="goal-dialog" aria-labelledby="custom-goal-title" onCancel={lambda (e: any) { revision.current += 1; draft = selectedDraft; description = selectedDescription; }}>
            <h2 id="custom-goal-title">Find your goal direction</h2><p>Tell us what you would like to work toward. These pictures are editable examples, not predictions of your future body.</p>
            <div className="studio-grid"><div><GoalPicture style={draft.style} upper={draft.upper} lower={draft.lower}/>
                <label>Activity direction<select value={draft.style} onChange={lambda (e: ChangeEvent) { update(e.target.value, draft.upper, draft.lower); }}><option value="general_strength">General strength</option><option value="muscle">Muscle building</option><option value="lean_toned">Lean / toned</option><option value="fat_loss">Fat-loss support</option></select></label>
                <label>Upper-body emphasis (0–3)<input type="range" min="0" max="3" value={draft.upper} onChange={lambda (e: ChangeEvent) { update(draft.style, int(e.target.value), draft.lower); }}/></label>
                <label>Lower-body emphasis (0–3)<input type="range" min="0" max="3" value={draft.lower} onChange={lambda (e: ChangeEvent) { update(draft.style, draft.upper, int(e.target.value)); }}/></label>
                <p className="hint">0: not a priority · 1: maintain · 2: develop · 3: prioritize. These are preferences, not a workout dose.</p>
            </div><div>
                <div className="dialog-history" aria-live="polite">{[<p key={idx}>{line}</p> for (idx, line) in enumerate(transcript)]}</div><p role="status">{reply}</p>
                <label>Describe or refine your goal<textarea value={message} maxLength={1000} onChange={lambda (e: ChangeEvent) { message = e.target.value; }} placeholder="For example: prioritize arm strength, but keep some leg training."/></label>
                <p className="hint">{"Your goal text is sent to " if provider.external else "Goal assistant runs locally at "}{provider.destination} · {provider.text_model}. Photos are not sent with this dialogue.</p>
                {if provider.external { <label className="consent"><input type="checkbox" checked={consent} onChange={lambda (e: ChangeEvent) { consent = e.target.checked; }}/>Send my goal text and current draft to {provider.destination}.</label> }}
                <button type="button" onClick={refine} disabled={busy or not provider.ready or not message.strip() or (provider.external and not consent)}>{"Refining…" if busy else "Update example picture"}</button>
                {if not provider.ready { <p>{provider.error}</p> }}
            </div></div>
            {if abs(draft.upper - draft.lower) >= 2 { <aside className="balance-warning" role="status"><strong>Training balance reminder</strong><p>Your requested upper- and lower-body emphasis differ substantially. This does not establish a health problem or an unhealthy body ratio. Include appropriate strengthening across major muscle groups, adapted to your abilities and constraints.</p><a href="https://www.cdc.gov/physical-activity-basics/guidelines/adults.html" target="_blank" rel="noreferrer">Why whole-body activity matters (CDC)</a></aside> }}
            <div className="actions"><button type="button" className="primary" onClick={accept} disabled={busy}>Use this goal</button><button type="button" onClick={close}>Close</button></div>
        </dialog>
    </section>
}
