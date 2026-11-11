"""One explicit device copy; no tokens or passwords are copied into it."""
import from "react" { createElement }

glob OFFLINE_KEY = "stride.offline.v1";

def:pub read_offline() -> any {
    raw = localStorage.getItem(OFFLINE_KEY);
    if not raw { return None; }
    doc: any = JSON.parse(raw);
    if doc.version != 1 or not doc.snapshot or not Array.isArray(doc.pending) {
        raise ValueError( "Unrecognized offline data. Export or erase this device copy.");
    }
    return doc;
}

def:pub write_offline(doc: any) -> any {
    current = read_offline();
    if (current and current.revision != doc.revision) or (not current and doc.revision) {
        raise ValueError( "Offline data changed in another tab. Reload before editing.");
    }
    saved = {**doc, "revision": str(new(Date).getTime()) + "-" + str(Math.random())};
    localStorage.setItem(OFFLINE_KEY, JSON.stringify(saved));
    return saved;
}

def:pub erase_offline() {
    localStorage.removeItem(OFFLINE_KEY);
}

# Logging out explicitly removes device data, including pending drafts.
def:pub clear_for_logout() -> bool {
    try {
        doc = read_offline();
        if doc and len(doc.pending) > 0 and not window.confirm("Log out and erase unsynced offline drafts from this device?") { return False; }
        erase_offline();
        return True;
    } except Exception { return False; }
}

def:pub export_offline(doc: any) {
    BlobType: any = globalThis.Blob;
    URLApi: any = globalThis.URL;
    file = new(BlobType, [JSON.stringify(doc, None, 2)], {"type": "application/json"});
    url = URLApi.createObjectURL(file);
    a: any = document.createElement("a");
    a.href = url;
    a.download = "stride-offline-backup.json";
    a.click();
    setTimeout(lambda { URLApi.revokeObjectURL(url); }, 1000);
}
