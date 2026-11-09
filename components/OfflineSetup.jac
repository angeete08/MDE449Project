import from "virtual:pwa-register" { registerSW }
import from "@jac/runtime" { Link }

# Only public application assets and the anonymous /offline shell are cached.
# Authenticated POST responses are never intercepted by Workbox.
def:pub OfflineSetup() -> JsxElement {
    has status: str = "";
    can with entry {
        registerSW({
            "onOfflineReady": lambda { status = "App ready offline. Save a device copy from the Offline page before disconnecting."; },
            "onNeedRefresh": lambda { status = "An app update is ready. Close all Stride tabs and reopen after saving your drafts."; },
            "onRegisterError": lambda (err: any) { status = "Offline launch unavailable. Use HTTPS and a production build."; }
        });
    }
    return <div className="stride-offline-banner">
        <Link to="/offline">Offline workspace</Link>
        {status and <span role="status">{status}</span>}
    </div>;
}
