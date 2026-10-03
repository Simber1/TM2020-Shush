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

// CommonCarWind is an "engine" source too but sits in Ambiance with no group handle.
bool IsCarEngineSource(CAudioSourceEngine@ eng) {
    auto grp = eng.BalanceGroup;
    return (grp == CAudioSource::EAudioBalanceGroup::Player || grp == CAudioSource::EAudioBalanceGroup::OtherPlayers)
        && eng.AudioGroupHandle != 0xFFFFFFFF;
}
