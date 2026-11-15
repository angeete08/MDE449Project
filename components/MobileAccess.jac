import from "@jac/runtime" { Link }

# Personal offline copies are opt-in; API responses are never cached by the worker.
def:pub MobileAccess(mobile: bool = False) -> JsxElement {
    return
        <aside className="stride-phone-menu" aria-label="Stride on your phone">
            <details>
                <summary>Use Stride on your phone</summary>
                <div className="stride-phone-popover">
                <Link to="/mobile">Open Stride for your phone</Link>
                <h3>Add Stride to your home screen</h3>
                <p>On iPhone, open this site in Safari, tap Share, then Add to Home Screen. On Android, open it in Chrome and choose Add to home screen or Install app from the menu.</p>
                <p>Use the secure HTTPS address supplied by your host. Open Offline workspace to save a device copy and prepare drafts without a connection.</p>
                </div>
            </details>
        </aside>;
}
