import base64;
import from io { BytesIO }
import from PIL { Image }
import from .coach_profile { CoachProfile, validate_profile }
import from .coach_media { prepare_photo }
import from .camera_lifecycle { stop_tracks, is_current }

obj FakeTrack {
    has stopped: bool = False;
    def stop() -> None { self.stopped = True; }
}
obj FakeStream {
    has tracks: list[FakeTrack] = [];
    def getTracks() -> list[FakeTrack] { return self.tracks; }
}
test "camera cleanup stops every track and tolerates absent streams" {
    first = FakeTrack();
    second = FakeTrack();
    stop_tracks(FakeStream(tracks=[first, second]));
    assert first.stopped and second.stopped;
    stop_tracks(None);
}
test "cancel or unmount invalidates pending photo work" {
    assert is_current(True, 2, 2);
    assert not is_current(True, 3, 2);
    assert not is_current(False, 2, 2);
}

def _fixture(kind: str = "PNG", width: int = 80, height: int = 60) -> str {
    output = BytesIO();
    Image.new("RGB", (width, height), "green").save(output, format=kind);
    mime = {"PNG": "png", "JPEG": "jpeg", "WEBP": "webp"}[kind];
    return "data:image/" + mime + ";base64," + base64.b64encode(output.getvalue()).decode("ascii");
}

test "all goals and regions accept a manual profile without a photo" {
    for goal in ["fat_loss", "lean_toned", "muscle", "general_strength"] {
        for region in ["shoulders", "arms", "chest", "back", "core", "glutes", "legs", "full_body", "unknown"] {
            assert validate_profile(CoachProfile(goal=goal, region=region, start_date="2026-11-11", timezone="America/Detroit")).valid;
        }
    }
}
test "reject invalid profile fields on server" {
    result = validate_profile(CoachProfile(goal="invented", region="face", experience="expert", equipment=["unsupported"], weekdays=[], minutes=9, start_date="2026-02-30", timezone="fake/zone", constraints="x" * 1001));
    assert not result.valid;
    assert len(result.errors) == 9;
}
test "reject duplicate equipment days out of range and fractional minutes" {
    assert not validate_profile(CoachProfile(equipment=["mat", "mat"], start_date="2026-11-11")).valid;
    assert not validate_profile(CoachProfile(weekdays=[1, 1], start_date="2026-11-11")).valid;
    assert not validate_profile(CoachProfile(weekdays=[7], start_date="2026-11-11")).valid;
    assert not validate_profile(CoachProfile(minutes=(30.5 as any), start_date="2026-11-11")).valid;
}
test "valid date boundaries and duration limits" {
    assert validate_profile(CoachProfile(start_date="2028-02-29", minutes=10)).valid;
    assert validate_profile(CoachProfile(start_date="2026-12-31", minutes=120)).valid;
    assert not validate_profile(CoachProfile(start_date="20260228")).valid;
}
test "decode supported formats and return JPEG only" {
    for kind in ["PNG", "JPEG", "WEBP"] {
        result = prepare_photo(_fixture(kind));
        assert result.valid;
        assert result.width == 80 and result.height == 60;
        assert result.data_url.startswith("data:image/jpeg;base64,");
    }
}
test "reject forged corrupt unsupported and oversized inputs" {
    assert not prepare_photo(_fixture().replace("image/png", "image/jpeg")).valid;
    assert not prepare_photo("data:image/jpeg;base64,notbase64!!").valid;
    assert not prepare_photo("data:image/svg+xml;base64,PHN2Zz4=").valid;
    assert not prepare_photo("x" * 13981101).valid;
    assert not prepare_photo(_fixture(width=20)).valid;
    assert not prepare_photo(_fixture(width=8193, height=32)).valid;
    assert not prepare_photo(_fixture(width=4001, height=4000)).valid;
    encoded = _fixture();
    assert not prepare_photo(encoded[:80]).valid;
}
test "EXIF orientation applied and metadata removed" {
    source = Image.new("RGB", (80, 60), "blue");
    exif = source.getexif();
    exif[274] = 6;
    exif[315] = "PRIVATE AUTHOR";
    output = BytesIO();
    source.save(output, format="JPEG", exif=exif);
    result = prepare_photo("data:image/jpeg;base64," + base64.b64encode(output.getvalue()).decode("ascii"));
    assert result.valid and result.width == 60 and result.height == 80;
    with Image.open(BytesIO(base64.b64decode(result.data_url.split(",", 1)[1]))) as decoded {
        assert len(decoded.getexif()) == 0;
        assert "icc_profile" not in decoded.info;
    }
}
test "large valid photo is reduced without changing aspect ratio" {
    result = prepare_photo(_fixture(width=2000, height=1000));
    assert result.valid and result.width == 1600 and result.height == 800;
}
test "animation rejected" {
    output = BytesIO();
    Image.new("RGB", (80, 60), "blue").save(output, format="PNG", save_all=True, append_images=[Image.new("RGB", (80, 60), "red")], duration=100, loop=0);
    assert not prepare_photo("data:image/png;base64," + base64.b64encode(output.getvalue()).decode("ascii")).valid;
}
