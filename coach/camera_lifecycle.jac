"""Small browser-independent helpers, shared by capture and lifecycle tests."""
def stop_tracks(stream: any) -> None {
    if stream {
        for track in stream.getTracks() { track.stop(); }
    }
}

def is_current(active: bool, current: int, ticket: int) -> bool {
    return active and current == ticket;
}
