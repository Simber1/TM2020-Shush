// The hook patches game code found by byte pattern, The plugin is disabled until the game version is verified as safe
// using hardcoded KnownSafeVersions, the version-compat config on openplanet.dev, 
// or the user trusting the current version in the settings tab.
namespace GameVersion {
    const string[] KnownSafeVersions = {
        "2026-02-02_17_51",
    };

    const string remoteUrl = "https://openplanet.dev/plugin/Shush/config/version-compat";
    bool CheckedVersion = false;
    bool LocalGameVersionSafe = false;
    bool RemoteSaysSafe = false;
    bool TempManualOverride = false;
    string currentGameVersion = "";

    bool Verified() {
        return LocalGameVersionSafe || RemoteSaysSafe;
    }

    bool ManuallyTrusted() {
        return currentGameVersion != "" && S_TrustedGameVersion == currentGameVersion;
    }

    bool get_safe() { 
        return LocalGameVersionSafe || RemoteSaysSafe || ManuallyTrusted() || TempManualOverride; 
    }

    void CheckVersion() {
        currentGameVersion = GetApp().SystemPlatform.ExeVersion;
        LocalGameVersionSafe = KnownSafeVersions.Find(currentGameVersion) != -1;

        if (!LocalGameVersionSafe) {
            RemoteSaysSafe = QueryRemoteSafe();
        }

        CheckedVersion = true;

        if (!safe){
            warn("GameVersion: " + currentGameVersion + " not verified, plugin disabled");
            UI::ShowNotification("Shush disabled", "Game version " + currentGameVersion + " isn't verified yet. "
            "You can enable it anyway in the plugin settings, Game Version tab.", 
            vec4(0.85, 0.45, 0.1, 1.0), 20000);
        }
    }

    bool QueryRemoteSafe() {
        uint attempts = 0;
        while (attempts < 5) {
            attempts++;
            if (attempts > 1) {
                sleep(1000);
            }
            auto request = Net::HttpGet(remoteUrl);
            while (!request.Finished()) yield();
            if (request.ResponseCode() == 404) {
                trace("GameVersion: no compatdata published");
                return false;
            }
            if (request.ResponseCode() != 200) {
                warn("GameVersion: compatdata request failed (" + request.ResponseCode() + ": " 
                + request.Error() + "), attempt: #" + attempts);
                continue;
            }
            try {
                auto data = Json::Parse(request.String());
                string PluginVersion = Meta::ExecutingPlugin().Version;
                if (!data.HasKey(PluginVersion) || data[PluginVersion].GetType() != Json::Type::Object) return false;
                return data[PluginVersion].HasKey(currentGameVersion);
            } catch {
                warn("GameVersion: bad compatdata json: " + getExceptionInfo());
            }
        }
        return false;
    }

    void EnableTemporarily() { TempManualOverride = true; }
    void EnableAndTrust() { S_TrustedGameVersion = currentGameVersion; }
    void ForgetManuallyTrusted() { S_TrustedGameVersion = ""; }

    string GetStatus() {
        if (!CheckedVersion) return "checking";
        if (LocalGameVersionSafe) return "verified";
        if (RemoteSaysSafe) return "verified (openplanet.dev)";
        if (ManuallyTrusted()) return "trusted manually by you";
        if (TempManualOverride) return "enabled until restart";
        return "not verified, plugin disabled";
    }

}

[SettingsTab name="Game Version" icon="ExclamationTriangle" order=99]
void RenderGameVersionTab() {
    UI::Text("Game version: " + GameVersion::currentGameVersion);
    UI::Text("Status: " + GameVersion::GetStatus());
    UI::Separator();
    if (!GameVersion::Verified() && !GameVersion::ManuallyTrusted()) {
        if (!GameVersion::safe) {
            UI::TextWrapped("The plugin patches game code it finds by byte pattern. After a game update that can crash the game, "
                "so it stays off until the new version has been checked. Enable it at your own risk.");
            if (UI::Button("Enable until restart")) GameVersion::EnableTemporarily();
        }
        if (UI::Button("Enable and remember this version")) GameVersion::EnableAndTrust();
    }
    if (S_TrustedGameVersion.Length > 0) {
        UI::Text("Remembered version: " + S_TrustedGameVersion);
        if (UI::Button("Forget")) GameVersion::ForgetManuallyTrusted();
    }
}
