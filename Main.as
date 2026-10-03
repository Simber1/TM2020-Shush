array<uint> g_lastFocus;

void Main() {
    GameVersion::CheckVersion();
}

void OnDestroyed() { VolHook::RemoveHook(); }
void OnDisabled() { VolHook::RemoveHook(); }

void Update(float dt) {
    DriveState state = ReadDriveState();
    bool driving = S_Enabled && GameVersion::safe && state.IsDriving;

    if (GameVersion::safe) VolHook::Find(); // do the pattern scan before driving to avoid stutter on first drive

    if (!driving) {
        VolHook::RemoveHook();
    }

    auto audio = GetApp().AudioPort;
    if (audio is null) return;
    g_lastFocus = FocusHandles(audio);

    if (driving) {
        VolHook::ApplyHook();
    } 
}
