import from "qrcode" { toDataURL }

def:pub MobileAccess() -> JsxElement {
    has link: str = "",
        qr: str = "",
        error: str = "";

    async can with entry {
        link = window.location.origin + "/mobile";
        try {
            qr = await toDataURL(link, {"margin": 2, "width": 220});
        } except Exception {
            error = "Could not generate the mobile QR code. Open the mobile link directly instead.";
        }
    }

    return
        <section className="stride-mobile-access mx-auto grid max-w-6xl gap-6 px-6 pb-16 md:grid-cols-[1fr_auto] md:items-center">
            <div className="flex flex-col gap-3">
                <span className="text-sm font-medium text-primary">STRIDE ON YOUR PHONE</span>
                <h2 className="text-2xl font-semibold tracking-tight">Your fitness plan, ready to go.</h2>
                <p className="max-w-xl text-sm text-muted-foreground">
                    Scan the QR code to open Stride’s mobile dashboard. Sign in or create an account to see your workouts, meals, progress, health, and Coach.
                </p>
                {link and <a className="w-fit text-sm font-medium text-primary underline underline-offset-4" href={link}>Open the mobile version</a>}
                {error and <p className="text-sm text-muted-foreground" role="status">{error}</p>}
            </div>
            {qr and
                <div className="stride-qr-card flex w-fit flex-col items-center gap-2 rounded-2xl border bg-card p-4 shadow-sm">
                    <img src={qr} width={220} height={220} alt="QR code to open the Stride mobile dashboard"/>
                    <a className="text-sm font-medium text-primary underline underline-offset-4" href={qr} download="stride-mobile-qr.png">Download QR code</a>
                </div>}
        </section>;
}
