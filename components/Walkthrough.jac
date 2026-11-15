import from ..services.stride { finish_walkthrough }
import from .ui.dialog { Dialog, DialogContent, DialogTitle, DialogDescription }
import from "react" { useEffect }

def:pub Walkthrough(onClose: Callable[[], None], onNavigate: Callable[[str], None], activeTab: str) -> JsxElement {
    has step: int = 0, busy: bool = False, expanded: bool = True, refocus: int = 0;
    pages = [
        {"title": "Welcome to Stride", "tab": "today", "selector": "", "body": "Explore the real app with a small guide beside you. Each step opens its feature, then you can click, try it and move on whenever you like. Changes you choose to save are real. This tour is optional."},
        {"title": "Today · your daily energy", "tab": "today", "selector": "[data-tour='today-energy']", "body": "Your energy balance is first: food intake, checked workouts and logged activity for today's date. Try opening Log activity to inspect the fields; cancel if you do not want to save. The page remains fully usable."},
        {"title": "Plan · workouts & calendar", "tab": "plan", "selector": "[data-tour='plan']", "body": "Explore a workout or switch calendar weeks. Check an exercise only when completed. Workout estimates, logged activities and the day's total update together. Difficulty feedback is separate. You can preview next week without changing your saved workouts."},
        {"title": "Meals · record your intake", "tab": "meals", "selector": "[data-tour='meals']", "body": "Try the food lookup or type a food and calories. Save only if you want to record that intake. Photo estimates are optional and need cloud access; review or correct them before saving. Return to Today to see your updated energy balance."},
        {"title": "Coach · try the goal studio", "tab": "coach", "selector": "[data-tour='studio']", "body": "A photo is optional. Choose a focus manually, confirm/edit your goal, then choose equipment and days. Click Confirm preferences & generate preview to try it without saving. Review the exercises before Save next week. Chat uses Gemini online; the photo studio displays its own local/cloud provider."},
        {"title": "History · saved progress & chat", "tab": "history", "selector": "[data-tour='history']", "body": "Explore saved workout weeks and this week's Coach conversations. Expand a saved exchange if available. Older chat weeks are deleted on your next account visit. You control the delete buttons; the tour does not delete or save anything for you."},
        {"title": "Offline · prepare before disconnecting", "tab": "history", "selector": "[data-tour='offline-access']", "body": "Open Offline workspace in another tab to inspect it while this guide stays here. Saving a device copy is optional and explicit. Later, check workouts locally and choose Sync drafts after reconnecting. Phone setup is beside the Offline workspace link."}
    ];
    useEffect(lambda {
        if step == 0 { return; }
        selector = str(pages[step]["selector"]);
        timer = setTimeout(lambda {
            target: any = document.querySelector(selector);
            if target {
                target.classList.add("tour-highlight");
                target.scrollIntoView({"behavior": "smooth", "block": "start"});
            }
        }, 80);
        return lambda {
            clearTimeout(timer);
            target: any = document.querySelector(selector);
            if target { target.classList.remove("tour-highlight"); }
        };
    }, [step, activeTab, refocus]);

    def go(next_step: int) {
        step = next_step;
        expanded = True;
        if next_step > 0 { onNavigate(str(pages[next_step]["tab"])); }
    }
    def show_feature() {
        onNavigate(str(pages[step]["tab"]));
        refocus = refocus + 1;
    }
    async def finish() {
        if busy { return; }
        busy = True;
        onClose();
        try { await finish_walkthrough(); } except Exception { }
    }
    if step == 0 {
        return <Dialog open={True} onOpenChange={lambda (open: bool) { if not open { finish(); } }}><DialogContent showCloseButton={False} className="walkthrough-card">
            <p className="walkthrough-step">{"QUICK TOUR · 1 / " + str(len(pages))}</p>
            <DialogTitle>{pages[0]["title"]}</DialogTitle><DialogDescription>{pages[0]["body"]}</DialogDescription>
            <div className="walkthrough-navigation"><button type="button" disabled={busy} onClick={lambda { go(1); }}>Explore Today</button></div>
            <button type="button" className="walkthrough-skip" disabled={busy} onClick={finish}>Skip tour</button>
        </DialogContent></Dialog>;
    }
    return <aside className={"tour-guide" + (" minimized" if not expanded else "")} aria-label="Interactive Stride tour">
        <div className="tour-guide-heading"><span>{"TRY STRIDE · " + str(step + 1) + " / " + str(len(pages))}</span><button type="button" onClick={lambda { expanded = not expanded; }}>{"Hide guide" if expanded else "Show guide"}</button></div>
        {expanded and <div className="tour-guide-body">
            <h2>{pages[step]["title"]}</h2><p>{pages[step]["body"]}</p>
            <p className="tour-hint">Click and try the highlighted feature. No action is required to continue.</p>
            <button type="button" className="tour-show-feature" onClick={show_feature}>Show this feature</button>
            {step == len(pages) - 1 and <a href="/offline" target="_blank" rel="noopener noreferrer">Try Offline workspace in a new tab ↗</a>}
        </div>}
        {expanded and <div className="tour-guide-navigation"><button type="button" onClick={lambda { go(step - 1); }}>Back</button>
                {step < len(pages) - 1 and <button type="button" onClick={lambda { go(step + 1); }}>Next</button>}
                {step == len(pages) - 1 and <button type="button" disabled={busy} onClick={finish}>Finish tour</button>}
            </div>}
        <button type="button" className="tour-guide-skip" disabled={busy} onClick={finish}>Skip tour</button>
    </aside>;
}
