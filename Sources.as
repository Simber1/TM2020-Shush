array<uint> FocusHandles(CAudioPort@ audio) {
    array<uint> handles;
    for (uint i = 0; i < audio.Listeners.Length; i++) {
        CAudioListener@ listener = audio.Listeners[i];
        for (uint j = 0; j < listener.AudioGroupHandlesInFocus.Length; j++) {
            uint handle = listener.AudioGroupHandlesInFocus[j];
            if (handles.Find(handle) == -1) handles.InsertLast(handle);
        }
    }
    return handles;
}

// the car the camera follows has its group handle in the listener focus list, ghosts don't
bool IsOwnCar(uint audioGroupHandle) {
    return g_lastFocus.Find(audioGroupHandle) >= 0;
}

// a car's sounds carry its group handle and sit in Player, Bengs (impacts) or GameUI (the slow-mo loop);
// music, menus, ambiance, wind and real UI sounds have no handle (0xFFFFFFFF). OtherPlayers is unused today.
bool IsCarAudioSource(CAudioSource@ src) {
    auto grp = src.BalanceGroup;
    return (grp == CAudioSource::EAudioBalanceGroup::Player || grp == CAudioSource::EAudioBalanceGroup::OtherPlayers
        || grp == CAudioSource::EAudioBalanceGroup::Bengs || grp == CAudioSource::EAudioBalanceGroup::GameUI)
        && src.AudioGroupHandle != 0xFFFFFFFF;
}
