# Streaming module (milestone M4)

Full-speed Steam gaming on iPhone via the GameStream protocol. The protocol
core is vendored here:

- `moonlight-common-c/` — pinned at commit `f900dd4767759c7b9d0e93bcea666b55c69ea62f` (GPL-3.0).
  Ships its own `enet/` fork which MUST be used (upstream libenet breaks the
  protocol — see their README).

## Wiring plan (what iOS must provide around the core)

The C core is callback-driven; `moonlight-common-c/src/` declares the client
callbacks in `MoonlightClient.h` (`AUDIO_INITIALIZER`, `DECODER_RENDERER_CALLBACKS`,
`_RENDERER_CALLBACKS`, `CONNECTION_LISTENER_CALLBACKS`, `PLATFORM_CALLBACKS`).
The iOS side implements:

| Concern | Implementation |
| --- | --- |
| Host discovery | `MoonlightDiscovery.swift` (NWBrowser, `_nvstream._tcp`) — done |
| Pairing PIN flow | `LiController`-style state machine around `LiStartServer`/pairing APIs |
| Video decode | VideoToolbox (`VTDecompressionSession`), H.264 baseline first, HEVC/AV1 for hosts that offer it |
| Presentation | `Renderer/` Metal pipeline (reuse UTM's renderer layering) — full-screen quad from CVPixelBuffer via `CVMetalTextureCache` |
| Audio | `AudioUnit` (RemoteIO) output at the host's stream sample rate |
| Input | `GameController` framework (MFi/Xbox/PS) mapped to `LiSendMultiControllerEvent`; touch fallback for mouse/keyboard |
| Latency | Keep decode on a dedicated dispatch queue; render on vsync; 5 GHz Wi-Fi or USB-attached network recommended |

## Enabling compilation

The core is vendored but not yet in the app target's compile sources (see
`scripts/inject_droiddeck.py` — add `moonlight-common-c/src/*.c`,
`moonlight-common-c/enet/*.c`, plus `SWIFT_INCLUDE_PATHS` pointing at a module
map exposing `MoonlightClient.h`). Until M4 lands, the Swift layer in this
directory compiles standalone (Network + SwiftUI only).

Host side: run [Sunshine](https://github.com/LizardByte/Sunshine) on the PC
(open source) — or GeForce Experience for NVIDIA GameStream. Steam Big Picture
streamed through it is the "Deck on your phone" experience at full frame rate.
