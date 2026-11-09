import from "@jac/runtime" { Link }

# Installation is deliberately online-only: account and health responses are
# never copied into a service-worker cache.
def:pub MobileAccess(mobile: bool = False) -> JsxElement {
    return
        <aside className="stride-mobile-access" aria-label="Stride on your phone">
            {if not mobile {
                <Link to="/mobile" className="font-medium underline underline-offset-4">Open Stride for your phone</Link>
            }}
            <details>
                <summary>Add Stride to your home screen</summary>
                <p>On iPhone, open this site in Safari, tap Share, then Add to Home Screen. On Android, open it in Chrome and choose Add to home screen or Install app from the menu.</p>
                <p>Use the secure HTTPS address supplied by your host. Stride needs an internet connection to load and save your account. Apple Health sync still uses the Stride Health iOS companion.</p>
            </details>
        </aside>;
}
