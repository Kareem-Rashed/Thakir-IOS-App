# Digital Sebha — Developer README

A compact, developer-focused README for the Digital Sebha SwiftUI app.

Purpose

- Lightweight dhikr (prayer beads) counter with voice recognition and per-sebha audio prompts.

Key points

- MVVM SwiftUI app (iOS 15+ / Xcode 15+)
- Arabic speech recognition with normalization (diacritics/Alifs/invisible chars) for robust matching
- Per-sebha audio recordings persisted to the app Documents directory and referenced by filename
- Daily counters, reorderable sebhas, reset daily/all-statistics capabilities

Quick start

1. Open in Xcode 15+: `open SebhaNew.xcodeproj`
2. Build & run on a simulator or device (grant microphone permission for voice features)

Project layout (important files)

- `SebhaNewApp.swift` — App entry
- `ContentView.swift` — Main tab container (uses `CustomTabBar`)
- `ViewModels/SebhaViewModel.swift` — Core logic: selection, counters, persistence, voice handling
- `Models/SebhaModels.swift` — Data models (Sebha, sessions, stats)
- `Views/Home/HomeView.swift` — Minimal home UI (big counter circle, selector, voice toggle)
- `Views/Sebhas/SebhasView.swift` — Sebha management + record/play UI
- `Views/Profile/ProfileView.swift` — Reset controls and statistics
- `Utils/Extensions.swift` — `normalizedArabic()` and other helpers
- `Utils/Constants.swift` — UserDefaults keys and constants

Development notes

- Recordings are saved by filename in UserDefaults and reconstructed at runtime from the Documents directory. Verify files exist after app updates or reinstalls.
- Arabic normalization is central to reliable speech matching. See `String.normalizedArabic()` in `Utils/Extensions.swift`.
- Reordering updates indices and persists the current selection to avoid mismatches between UI order and voice mappings.
- Debug logs are present in the voice path; gate behind a DEBUG flag before production.

Running tests

- Unit tests: `xcodebuild test -scheme SebhaNew -destination 'platform=iOS Simulator,name=iPhone 15'`
- UI tests use the same command with the UI test target

Screenshots (actual files)

- First: sebhas list
- Second: home page

![Sebhas — List & Record](./Screenshots/Simulator Screenshot - iPhone 17 Pro Max - 2025-11-25 at 20.47.07.png)
![Home — Big Counter](./Screenshots/Simulator Screenshot - iPhone 17 Pro Max - 2025-11-25 at 20.47.30.png)

Contributing

- Fork, create a branch, and open a PR. Keep changes scoped and include tests where relevant.

License

- MIT — see `LICENSE`.

Contact

- Author: Kareem Rashed — update links inside the repo as needed.
