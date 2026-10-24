// Each audio update the game copies every sound's state into its CAudioSource. One branch per source type
// (engine, surface, multi, other) stores the new volume through rdi = &source.VolumedB, and an optional fade can
// store it again. Every path then reaches the hooked instruction with rbx = the source and its final volume:
//   mulss xmm0, [rdi]             ; MEMORY_PATTERN starts here
//   movss [rdi], xmm0             ; fade re-store
//   mov esi, [r14+disp8]
//   test esi, esi
//   je ...
//   mov eax, 1
//   mov [rbx+disp32], eax
//   mov edi, [r14+disp32]         <- hooked at HOOK_OFFSET (7 bytes = 5-byte jmp + 2)
//   test edi, edi
const string MEMORY_PATTERN = "F3 0F 59 07 F3 0F 11 07 41 8B 76 ?? 85 F6 74 ?? B8 01 00 00 00 89 83 ?? ?? 00 00 41 8B BE ?? ?? 00 00 85 FF";
const float MUTED_DB = -100.0;
const uint HOOK_OFFSET = 27;
const uint VOLUMEDB_OFFSET = 0x64;

namespace VolHook {
    uint64 hookPtr = 0;
    Dev::HookInfo@ hook;
    string previousWarning = "";
    bool searchFailed = false;

    void Error(const string &in msg) {
        if (msg == previousWarning) return;
        previousWarning = msg;
        warn("VolHook: " + msg);
    }

    bool Find() {
        if (hookPtr != 0) return true; // Already found pattern
        if (searchFailed) return false;  // Don't try again if we already failed to find the pattern

        uint64 ptr = Dev::FindPattern(MEMORY_PATTERN);

        if (ptr == 0) {
            UI::ShowNotification("Shush", "Ghost sound code not found in this game version, nothing will be muted. This could be caused by a game update or a conflicting plugin", vec4(0.8, 0.3, 0.1, 1.0), 15000);
            searchFailed = true;
            return false;
        }

        hookPtr = ptr + HOOK_OFFSET;
        trace("VolHook: volume hook point found at " + Text::FormatPointer(hookPtr));
        return true;
    }

    bool ApplyHook() {
        if (hook !is null) return true;
        if (!Find()) return false;

        if (Dev::Read(hookPtr, 3) != "41 8B BE") {
            Error("unexpected bytes at hook site: " + Dev::Read(hookPtr, 7));
            return false;
        }

        @hook = Dev::Hook(hookPtr, 2, "VolHook::OnAfterVolumeUpdate", Dev::PushRegisters::SSE);

        if (hook is null) {
            Error("Dev::Hook returned null");
            return false;
        }

        previousWarning = "";
        trace("VolHook: hooked");
        return true;
    }

    void RemoveHook() {
        if (hook is null) return;
        Dev::Unhook(hook);
        @hook = null;
        trace("VolHook: unhooked");
    }

    void OnAfterVolumeUpdate(CMwNod@ rbx) {
        if (rbx is null) {
            Error("rbx is null");
            return;
        }

        auto audioSource = cast<CAudioSource>(rbx);

        if (audioSource is null) {
            Error("hooked object is not a CAudioSource");
            return;
        }

        if (!IsCarAudioSource(audioSource) || IsOwnCar(audioSource.AudioGroupHandle)) return;
        Dev::SetOffset(audioSource, VOLUMEDB_OFFSET, MUTED_DB);
    }
}
