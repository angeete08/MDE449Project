"""User-triggered capture; only validated, metadata-free previews enter state."""
import from "react" { useEffect }
import from .coach_media { PhotoResult, prepare_photo }
import from .camera_lifecycle { stop_tracks, is_current }
import from .vision_ui { VisionPanel }

def:pub PhotoCapture(onFocus: Callable[[str], None]) -> JsxElement {
    has preview: str = "", original: str = "", error: str = "", notice: str = "",
        busy: bool = False, camera: bool = False, requesting: bool = False,
        crop: int = 100, offsetX: int = 50, offsetY: int = 50;
    has stream: Ref[any] = Ref(None), video: Ref[any] = Ref(None),
        generation: Ref[int] = Ref(0), active: Ref[bool] = Ref(True);
    browser: any = window;

    def stopCamera() -> None {
        if stream.current {
            stop_tracks(stream.current);
            stream.current = None;
        }
        if video.current { video.current.srcObject = None; }
        camera = False;
    }

    useEffect(lambda {
        active.current = True;
        return lambda {
            active.current = False;
            generation.current += 1;
            if stream.current {
                stop_tracks(stream.current);
                stream.current = None;
            }
        };
    }, []);

    def clearPhoto() -> None {
        generation.current += 1;
        stopCamera();
        requesting = False;
        busy = False;
        preview = "";
        original = "";
        error = "";
        notice = "Photo removed. You can continue with manual selection.";
    }

    async def normalize(data: str, ticket: int, replaceOriginal: bool) -> None {
        if not is_current(bool(active.current), generation.current as int, ticket) { return; }
        try {
            result = await prepare_photo(data);
            if not active.current or ticket != generation.current { return; }
            if not result.valid { error = result.error; return; }
            preview = result.data_url;
            if replaceOriginal { original = result.data_url; }
            crop = 100;
            offsetX = 50;
            offsetY = 50;
            notice = "Photo ready · metadata removed · kept only until removal or reload.";
        } except Exception {
            if active.current and ticket == generation.current { error = "Photo could not be prepared. Check the local server and try again."; }
        } finally { if active.current and ticket == generation.current { busy = False; } }
    }

    def chooseFile(e: ChangeEvent) -> None {
        target: any = e.target;
        file = target.files[0];
        e.target.value = "";
        if not file { return; }
        stopCamera();
        generation.current += 1;
        ticket = generation.current;
        requesting = False;
        error = "";
        notice = "";
        if file.size > 10485760 { error = "Image must be at most 10 MB."; return; }
        if file.type not in ["image/jpeg", "image/png", "image/webp"] { error = "Choose a JPEG, PNG or WebP image."; return; }
        busy = True;
        reader: any = new(browser.FileReader);
        reader.onload = lambda (event: any) { normalize(str(reader.result), ticket, True); };
        reader.onerror = lambda (event: any) { if active.current and ticket == generation.current { error = "Could not read that file."; busy = False; } };
        reader.readAsDataURL(file);
    }

    async def openCamera() -> None {
        stopCamera();
        generation.current += 1;
        ticket = generation.current;
        error = "";
        notice = "";
        if not browser.navigator.mediaDevices or not browser.navigator.mediaDevices.getUserMedia {
            error = "Camera unavailable. Use a photo upload or continue manually. Camera access requires HTTPS or localhost.";
            return;
        }
        requesting = True;
        try {
            acquired = await browser.navigator.mediaDevices.getUserMedia({"video": {"facingMode": "environment"}, "audio": False});
            if not active.current or ticket != generation.current {
                stop_tracks(acquired);
                return;
            }
            stream.current = acquired;
            camera = True;
            # Video stays mounted so attaching the stream never races a render.
            if video.current {
                video.current.srcObject = acquired;
                await video.current.play();
            } else { stopCamera(); }
        } except Exception {
            if active.current and ticket == generation.current { stopCamera(); error = "Camera access was unavailable or denied. Upload a photo or continue manually."; }
        } finally { if active.current and ticket == generation.current { requesting = False; } }
    }

    def capture() -> None {
        if not video.current or not video.current.videoWidth { error = "Camera is still starting. Try again shortly."; return; }
        canvas: any = document.createElement("canvas");
        scale = min(1, 1600 / max(video.current.videoWidth, video.current.videoHeight));
        canvas.width = int(video.current.videoWidth * scale);
        canvas.height = int(video.current.videoHeight * scale);
        canvas.getContext("2d").drawImage(video.current, 0, 0, canvas.width, canvas.height);
        data = canvas.toDataURL("image/jpeg", 0.9);
        stopCamera();
        generation.current += 1;
        busy = True;
        normalize(str(data), generation.current as int, True);
    }

    def applyCrop() -> None {
        generation.current += 1;
        ticket = generation.current;
        busy = True;
        error = "";
        pic: any = new(browser.Image);
        pic.onload = lambda (e: any) {
            if not active.current or ticket != generation.current { return; }
            w = int(pic.naturalWidth * crop / 100);
            h = int(pic.naturalHeight * crop / 100);
            canvas: any = document.createElement("canvas");
            canvas.width = w;
            canvas.height = h;
            canvas.getContext("2d").drawImage(pic, (pic.naturalWidth - w) * offsetX / 100, (pic.naturalHeight - h) * offsetY / 100, w, h, 0, 0, w, h);
            normalize(str(canvas.toDataURL("image/jpeg", 0.9)), ticket as int, False);
        };
        pic.onerror = lambda (e: any) { if active.current and ticket == generation.current { error = "Could not crop the image."; busy = False; } };
        pic.src = original;
    }

    <div className="capture">
        <div className="privacy"><strong>Private, optional photo</strong><p>The local server checks your photo and removes metadata. Analysis happens only when you request it. API mode asks for consent before sending a photo to the displayed provider. This app does not save photos.</p></div>
        <video ref={video} hidden={not camera} autoPlay muted playsInline aria-label="Live camera preview"/>
        {if not camera {
            if preview { <img className="preview" src={preview} alt="Your selected coach photo"/> }
            else { <div className="empty"><span aria-hidden="true">＋</span><h3>A starting point, if you want one</h3><p>Use your camera or choose a photo.<br/>You can also skip this step entirely.</p></div> }
        }}
        <div className="actions"><label className="button">Upload photo<input className="file" type="file" accept="image/jpeg,image/png,image/webp" onChange={chooseFile} disabled={busy or requesting}/></label><button type="button" onClick={openCamera} disabled={busy or requesting}>{"Retake with camera" if preview else "Open camera"}</button></div>
        {if camera { <div className="actions"><button className="primary" type="button" onClick={capture}>Take photo</button><button type="button" onClick={lambda { generation.current += 1; stopCamera(); }}>Close camera</button></div> }}
        {if requesting { <div><p role="status">Waiting for camera permission…</p><button type="button" onClick={lambda { generation.current += 1; requesting = False; stopCamera(); }}>Cancel camera request</button></div> }}
        {if preview and not camera {
            <fieldset disabled={busy}><legend>Crop from original</legend><p className="hint">Keep {crop}% of the image. Apply to preview the result; restore at any time.</p>
                <label>Crop size<input type="range" min="50" max="100" value={crop} onChange={lambda (e: ChangeEvent) { crop = int(e.target.value); }}/></label>
                <label>Horizontal position<input type="range" min="0" max="100" value={offsetX} onChange={lambda (e: ChangeEvent) { offsetX = int(e.target.value); }}/></label>
                <label>Vertical position<input type="range" min="0" max="100" value={offsetY} onChange={lambda (e: ChangeEvent) { offsetY = int(e.target.value); }}/></label>
                <div className="actions"><button type="button" onClick={applyCrop}>Apply crop</button><button type="button" onClick={lambda { preview = original; crop = 100; offsetX = 50; offsetY = 50; }}>Restore original</button></div>
            </fieldset>
        }}
        {if preview or busy { <button type="button" onClick={clearPhoto}>Remove photo / cancel</button> }}
        <p className="error" role="alert">{error}</p><p className="hint" role="status">{"Preparing photo…" if busy else notice}</p>
        <p className="hint">JPEG, PNG or WebP · up to 10 MB and 16 MP.<br/>Manual focus selection is always available.</p>
        {if preview and not camera and not busy { <VisionPanel key={preview} photo={preview} onFocus={onFocus}/> }}
    </div>
}
