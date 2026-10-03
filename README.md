# DroidDeck for iOS

An unofficial iOS port of the [DroidDeck](https://github.com/Droid-Deck/DroidDeck)
concept: a **SteamOS-style gaming environment on your iPhone**, built entirely
on open-source components and distributed as a sideloadable `.ipa`.

> **Not affiliated** with Valve (Steam/SteamOS are their trademarks) or the
> Droid-Deck organization. GPL-3.0 licensed; see *About & Licenses* below.

## How it works — and what to honestly expect

The Android original runs an ARM64 Linux runtime through **proot** with
**FEX-EMU** and host GPU thunks. iOS forbids that architecture outright (no
`fork()`, no `ptrace`, no driver loading), so this port runs the same recipe
inside a **fully emulated ARM64 Linux virtual machine** (QEMU, via UTM's
engine). Inside the VM, Steam's Big Picture mode runs the Deck-style UI.

| Mode | Experience |
| --- | --- |
| **Stream from your PC** | Full speed. Modern Steam games at 60 fps via GameStream (Sunshine on your PC). *The* way to actually play demanding games on iPhone (milestone M4). |
| **Local (JIT edition)** | Usable-slow Steam UI; lightweight/2D/older games are marginal. One-time "Enable JIT" toggle in SideStore/AltStore at launch. |
| **Local (SE edition)** | Interpreter-based emulation; no extra steps to install, noticeably slower. |

There is **no GPU acceleration** for the local VM today — no QEMU GPU backend
speaks Metal (the only GPU API iOS apps get). Local 3D is software-rendered.
The `gpu-rd/` directory tracks the paravirtual-GPU research (gfxstream/Venus
over MoltenVK) with explicit go/no-go gates.

Target devices: iPhones with **8 GB RAM** (15 Pro and newer); 6 GB devices
work with a reduced memory allocation.

## Getting the app

Download from [Releases] once CI has produced them:

- `DroidDeck-JIT.ipa` — primary experience
- `DroidDeck-SE.ipa` — zero-extra-steps fallback
- `DroidDeckOS-<version>-arm64.qcow2` — guest disk image (the app can also
  download this on first launch)

Sideload with [SideStore](https://sidestore.io), [AltStore](https://altstore.io)
or [Sideloadly](https://sideloadly.io). Free Apple IDs: 3-app limit, refresh
weekly (SideStore does it on-device). For the JIT edition, use SideStore's/
AltStore's *Enable JIT* after each install/launch (this port's equivalent of
the Android original's "disable child process restrictions" tweak).

## Building from source

Requires a Mac with Xcode for local builds; **GitHub Actions does everything
on push** (this mirrors how DroidDeck itself releases):

```bash
git clone <this repo> && cd droiddeck-ios
# CI: .github/workflows/build.yml   -> IPAs as artifacts
#     .github/workflows/build-image.yml -> DroidDeckOS qcow2
```

Manual local build (macOS, see `Documentation/iOSDevelopment.md` from UTM):

```bash
./scripts/build_dependencies.sh -p ios -a arm64
./scripts/build_dependencies.sh -p ios-tci -a arm64
./scripts/build_utm.sh -k iphoneos -s iOS -o build        # JIT edition
./scripts/build_utm.sh -k iphoneos -s iOS-SE -o build     # SE edition
./scripts/package.sh ipa build/UTM.xcarchive .
```

The guest image builds on any Ubuntu host with Docker:
`sudo ./image/build-image.sh 0.1.0` (see `image/README.md`).

## Repository layout

| Path | Contents |
| --- | --- |
| `Platform/DroidDeck/` | The custom launcher UI (SwiftUI) + streaming module |
| everything UTM-shaped | Fork of [UTM](https://github.com/utmapp/UTM) v5.0.6 (engine, QEMU integration, renderer) |
| `image/` | DroidDeckOS guest image build (Ubuntu arm64 + FEX + Steam + cage) |
| `gpu-rd/` | GPU acceleration research track (G0–G3 gates) |
| `scripts/` | UTM build scripts + `inject_droiddeck.py` (registers new Swift files in the Xcode project) |

Adding a Swift file to the app: drop it under `Platform/DroidDeck/` and run
`python3 scripts/inject_droiddeck.py`.

## Roadmap

- [x] **M1** — fork builds unsigned IPAs in CI (JIT + SE)
- [ ] **M2** — DroidDeckOS image boots to a graphical session
- [ ] **M3** — Steam Big Picture + audio + controllers, end-to-end on device
- [ ] **M4** — Moonlight streaming mode (full-speed gaming)
- [ ] **M5** — GPU acceleration research gates (gfxstream/Venus on MoltenVK)

## About & Licenses

This program is free software: you can redistribute it and/or modify it under
the terms of the **GNU General Public License as published by the Free
Software Foundation, version 3** (see `LICENSE`). It is a derivative work of:

- **UTM** v5.0.6 — Apache-2.0 (`LICENSES/LICENSE-UTM.txt`)
- **QEMU** — GPLv2, via [utmapp/QEMU](https://github.com/utmapp/QEMU)
- **moonlight-common-c** — GPL-3.0, vendored under
  `Platform/DroidDeck/Streaming/moonlight-common-c/`
- **Droid-Deck/DroidDeck** (GPL-3.0) — the original Android project; this
  port reuses its FEX runtime recipe and follows its release model

Internal Xcode target/product names retain the UTM identity for fork
stability; the user-visible app, bundle id (`com.droiddeck.*`) and display
name are DroidDeck.
