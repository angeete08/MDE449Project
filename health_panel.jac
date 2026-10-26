"""Apple Health panel: sends a sync request to the Stride Health iOS app and returns weekly averages."""
import from "react" { useEffect }
import from "qrcode" { toDataURL }
import from health_sync { start_health_sync, health_sync_status }

def:pub AppleHealthSync(onSynced: Callable[[dict[str, any]], None]) -> JsxElement {
    has syncId: str = "", link: str = "", qr: str = "", phase: str = "", received: int = 0, message: str = "", busy: bool = False;

    async def check(id: str) -> None {
        try {
            result = await health_sync_status(id, int(Date.now()));
            received = result["received"];
            if result["state"] == "complete" {
                phase = "complete";
                syncId = "";
                onSynced(result["summary"]);
                message = "Apple Health data received. Review the imported averages.";
            } elif result["state"] == "expired" {
                phase = "expired";
                syncId = "";
                message = "This sync request expired. Send a new one when your iPhone is ready.";
            } elif result["state"] == "receiving" {
                phase = "receiving";
                message = "Receiving Apple Health data from your iPhone…";
            }
        } except Exception { message = "Lost contact with the Stride server. Still trying…"; }
    }

    useEffect(lambda {
        id = syncId;
        timer = setInterval(lambda { check(id); }, 3000) if id else None;
        return lambda { if timer { clearInterval(timer); } };
    }, [syncId]);

    async def send -> None {
        if busy { return; }
        busy = True;
        message = "";
        try {
            result = await start_health_sync(window.location.href, int(0 - new(Date).getTimezoneOffset()));
            if not result["ok"] { message = result["message"]; phase = ""; return; }
            link = result["link"];
            received = 0;
            phase = "waiting";
            message = "Waiting for your iPhone. The request expires after " + str(result["expires_minutes"]) + " minutes without activity.";
            try { qr = await toDataURL(result["link"], {"margin": 1, "width": 176}); }
            except Exception { qr = ""; }
            syncId = result["sync_id"];
        } except Exception { message = "Could not create a sync request. Check that the Jac server is running."; }
        finally { busy = False; }
    }

    def cancel -> None {
        syncId = "";
        phase = "";
        message = "Sync request cancelled.";
    }

    <div className="health-sync">
        <div className="health-sync-top"><strong>Apple Health</strong><span className="tag">IPHONE APP</span></div>
        <p className="hint">Fill the averages from the last 28 days of steps, heart rate, sleep and workouts. Requires the Stride Health iOS app on an iPhone on the same Wi-Fi as this computer.</p>
        {if phase == "waiting" or phase == "receiving" {
            <div className="health-request">
                {if qr and phase == "waiting" { <img src={qr} width={176} height={176} alt="QR code that opens this sync request in Stride Health"/> }}
                <ol>
                    <li>Scan the code with the iPhone camera, or tap the link on the iPhone.</li>
                    <li>In Stride Health, check the server address and allow access.</li>
                    <li>Keep the app open until it says the data was sent.</li>
                </ol>
                <a className="quiet" href={link}>Open in Stride Health</a>
                {if received > 0 { <small>{str(received) + " samples received"}</small> }}
                <button type="button" className="quiet" onClick={cancel}>Cancel</button>
            </div>
        } else {
            <button type="button" className="quiet" onClick={send} disabled={busy}>{"Please wait…" if busy else ("Sync again" if phase == "complete" else "Send sync request to iPhone")}</button>
        }}
        {if message { <p className="health-status" role="status" aria-live="polite">{message}</p> }}
    </div>
}
