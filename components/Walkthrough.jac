import from ..services.stride { finish_walkthrough }
import from .ui.dialog { Dialog, DialogContent, DialogTitle, DialogDescription }

def:pub Walkthrough(onClose: Callable[[], None]) -> JsxElement {
    has step: int = 0, busy: bool = False, error: str = "";
    pages = [
        {"title": "Welcome to Stride", "body": "Make a weekly plan, check off exercises, track meals and choose your own pace. This quick tour is optional. You can reopen it from your dashboard."},
        {"title": "Today & Plan", "body": "Today shows your workout and activity goal. Plan has all seven days and a progress calendar. Check each exercise when finished; its estimated calories join the total above the difficulty buttons. Rate how the session felt to adjust later workouts. Rest or reduce effort whenever you need."},
        {"title": "Meals", "body": "Log food manually or look it up from bundled data. You can also review a Gemini meal-photo estimate, correct it and add it to intake. Intake and estimated workout energy are separate. Your calorie target is always your choice."},
        {"title": "Coach · Photo and goal studio", "body": "Chat asks Gemini general questions online. In the separate studio: 1. Upload a photo or choose a focus manually. 2. Confirm or edit the focus. 3. Choose a goal, equipment and days. 4. Generate, review and save next week's exercises. Photos are optional and are not medical assessments. The studio shows its own local Ollama or cloud provider; local Ollama still needs a reachable app server."},
        {"title": "History & offline workouts", "body": "History keeps saved workout weeks and this week's Coach conversations. Older chat weeks expire when you next visit. Use Offline workspace to explicitly save a device copy before disconnecting. Your local workout edits remain drafts until you choose Sync drafts. Phone setup lives at the upper right beside Offline workspace."}
    ];
    async def finish() {
        if busy { return; }
        busy = True;
        onClose();
        try { await finish_walkthrough(); }
        except Exception { # Tour stays optional if the server becomes unavailable.
        }
    }
    return <Dialog open={True} onOpenChange={lambda (open: bool) { if not open { finish(); } }}><DialogContent showCloseButton={False} className="walkthrough-card">
        <p className="walkthrough-step">{"QUICK TOUR · " + str(step + 1) + " / " + str(len(pages))}</p>
        <DialogTitle>{pages[step]["title"]}</DialogTitle><DialogDescription>{pages[step]["body"]}</DialogDescription>
        {error and <p role="alert">{error}</p>}
        <div className="walkthrough-navigation">
            <button type="button" disabled={busy or step == 0} onClick={lambda { step = step - 1; }}>Back</button>
            {step < len(pages) - 1 and <button type="button" disabled={busy} onClick={lambda { step = step + 1; }}>Next</button>}
            {step == len(pages) - 1 and <button type="button" disabled={busy} onClick={finish}>Start using Stride</button>}
        </div>
        <button type="button" className="walkthrough-skip" disabled={busy} onClick={finish}>Skip tour</button>
    </DialogContent></Dialog>;
}
