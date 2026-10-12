class DriveState {
    bool hasPlayground = false;
    bool viewingOwnPlayer = false;
    bool forceSpec = false;
    bool inEditor = false;
    bool online = false;

    SGamePlaygroundUIConfig::EUISequence currentUISequence = SGamePlaygroundUIConfig::EUISequence::None;

    bool get_IsDriving() {
        return hasPlayground && viewingOwnPlayer && !forceSpec && !inEditor && !online
            && currentUISequence == SGamePlaygroundUIConfig::EUISequence::Playing;
    }
}

DriveState ReadDriveState() {
    DriveState driveState;
    auto app = GetApp();
    driveState.inEditor = app.Editor !is null;
    auto currentPlayground = app.CurrentPlayground;
    driveState.hasPlayground = currentPlayground !is null;
    driveState.online = app.PlaygroundScript is null;

    if (driveState.hasPlayground && currentPlayground.GameTerminals.Length > 0) {
        auto gameTerminal = currentPlayground.GameTerminals[0];
        if (gameTerminal.ControlledPlayer !is null && gameTerminal.GUIPlayer !is null
            && gameTerminal.GUIPlayer.User.Id.Value == gameTerminal.ControlledPlayer.User.Id.Value) {
            driveState.viewingOwnPlayer = true;
        }
        driveState.currentUISequence = gameTerminal.UISequence_Current;
    }

    auto playgroundScript = cast<CSmArenaRulesMode>(app.PlaygroundScript);

    if (playgroundScript !is null && playgroundScript.UIManager !is null) {
        driveState.forceSpec = playgroundScript.UIManager.UIAll.ForceSpectator;
    }

    return driveState;
}
