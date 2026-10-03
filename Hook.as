// Each audio update the game recomputes every engine source's volume and stores it:
//   movss [rdi], xmm7          ; rdi = &CAudioSourceEngine.VolumedB
//   movss [rbx+disp32], xmm0   ; rbx = the source   <- hooked (8 bytes = 5-byte jmp + 3)
//   movss [rbx+disp8], xmm6
//   jmp ...
// Pattern starts at the second instruction: Ghosts++ overwrites the first instruction with NOPs to soften engine sounds when scrubbing replays.
const string MEMORY_PATTERN = "F3 0F 11 83 ?? 00 00 00 F3 0F 11 73 ?? E9 ?? ?? ?? ?? 48 8B 03 48 8D 7B ?? BA 00 30 01 10";
const string STORE = "F3 0F 11 3F"; // movss [rdi], xmm7
const string STORE_GHOSTPP = "90 90 90 90"; // Ghosts++ overrides the same addr with NOPs to soften engine sounds when scrubbing replays, we don't want to hook while that is happening.
const float MUTED_DB = -100.0;

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

        if (ptr != 0) {
            string store = Dev::Read(ptr - 4, 4);
            if (store != STORE && store != STORE_GHOSTPP) {
                Error("pattern found at " + Text::FormatPointer(ptr) + " but store bytes are " + store + ", not the expected bytes.");
                ptr = 0;
            }
        }

        if (ptr == 0) {
            UI::ShowNotification("Shush", "Engine sound code not found in this game version, nothing will be muted. This could be caused by a game update or a conflicting plugin", vec4(0.8, 0.3, 0.1, 1.0), 15000);
            searchFailed = true;
            return false;
        }

        hookPtr = ptr;
        trace("VolHook: volume store found at " + Text::FormatPointer(ptr - 4));
        return true;
    }

    bool ApplyHook() {
        if (hook !is null) return true;
        if (!Find()) return false;

        string store = Dev::Read(hookPtr - 4, 4);

        if (store == STORE_GHOSTPP) return false;  // Ghosts++ is currently scrubbing with lower audio set

        if (store != STORE) {
            Error("unexpected bytes at store: " + store);
            return false;
        }

        if (Dev::Read(hookPtr, 4) != "F3 0F 11 83") {
            Error("unexpected bytes at hook site: " + Dev::Read(hookPtr, 8));
            return false;
        }

        @hook = Dev::Hook(hookPtr, 3, "VolHook::OnAfterVolumeStore", Dev::PushRegisters::SSE);

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

    void OnAfterVolumeStore(CMwNod@ rbx, uint64 rdi) {
        if (rbx is null || rdi == 0) {
            Error("rbx is null or rdi is 0");
            return;
        }

        auto engine = cast<CAudioSourceEngine>(rbx);

        if (engine is null) {
            Error("hooked object is not a CAudioSourceEngine");
            return;
        }

        if (!IsCarEngineSource(engine) || IsOwnCar(engine.AudioGroupHandle)) return;
        Dev::Write(rdi, MUTED_DB);
    }
}
