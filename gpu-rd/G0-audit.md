# G0 — GPU acceleration feasibility audit (iOS host)

Status: **research track**. Nothing here ships in v1. Gates G0→G3 decide
whether accelerated local rendering ever lands; if any gate fails, streaming
remains the high-performance path.

## The problem, precisely

iOS apps may use the GPU **through Metal only** — no OpenGL, no Vulkan, no
kernel driver loading. A QEMU guest draws to a *virtual* GPU; making that
virtual GPU accelerated requires a host-side component that receives guest
GPU commands over the virtio-gpu channel and executes them against Metal.
No such backend exists today:

- **virglrenderer** (GL paravirtualization) requires host EGL/OpenGL ES 3.1+.
- **Venus** (Vulkan paravirtualization) requires host Vulkan 1.1+ with
  timeline semaphores, external memory, etc.
- **utmapp/QEMU** (what we and UTM ship) compiles neither on iOS; UTM itself
  documents no GPU acceleration on iOS.

Existence proof that the *pattern* works on Apple Silicon: Google's
**gfxstream** (guest drivers merged into Mesa, Sept 2024) is how the Android
Emulator — itself QEMU-derived — renders guest Vulkan/GLES through to Metal
on Apple-Silicon Macs, via a host-side layer that reaches Metal through
Vulkan-on-Metal translation.

## Candidate architectures

### A. gfxstream host renderer on MoltenVK

- Guest: Mesa `gfxstream` Vulkan/GLES drivers (in mainline Mesa 24.3+)
  speaking the gfxstream protocol over virtio-gpu context types.
- Host: build gfxstream's host renderer for iOS; its Vulkan consumption runs
  on **MoltenVK** (Vulkan-on-Metal, works on iOS).
- Emulator integration: crosvm-style virtio-gpu with rutabaga/gfxstream
  backend. utmapp/QEMU is upstream-QEMU based; AOSP's emulator QEMU fork
  carries the gfxstream wiring — this fork would need that ported.

### B. Venus on MoltenVK

- Guest: Mesa `venus` Vulkan driver (mainline).
- Host: venus requires crosvm/vtest-style server with Vulkan 1.1. MoltenVK's
  conformance gaps (timeline semaphore emulation, external memory on iOS,
  no VK_EXT_physical_device_drm, memory type mismatches) make this the
  weaker candidate, but it is the more "standard" Linux stack.

### C. virglrenderer on ANGLE(Metal)

- ANGLE has a Metal backend and nominally builds for iOS; virglrenderer's
  renderer core would target GLES3.1 via ANGLE. Guest gets GL only (no
  Vulkan → DXVK/vkd3d impossible → Wine/Proton D3D path degrades to
  WineD3D-on-GL). Lowest value of the three.

## G0 checklist (blocking audit before any code)

Run against current MoltenVK (iOS):

- [ ] Vulkan version & conformance level (need ≥ 1.1; check VK_VERSION_1_1)
- [ ] `VK_KHR_timeline_semaphore` (real or emulated) — gfxstream/Venus host
- [ ] External memory / `VK_KHR_external_memory_fd` equivalents on iOS
      (IOSurface interop is the only real path on iOS)
- [ ] Sync objects across process boundaries (fd export) — may not exist
- [ ] Max descriptor sets, push constants, feature bits vs gfxstream host
      requirements (`host/gfxstream/vulkan/cereal/host_vulkan_impl`)
- [ ] MoltenVK building for iOS arm64 + app-store/sideload viability
- [ ] ANGLE Metal backend status on iOS (for candidate C)

Plus repo-side:

- [ ] Locate AOSP emulator QEMU's virtio-gpu/gfxstream integration commits
      (`external/qemu`, device/generic/goldfish) and size the port into
      utmapp/QEMU (candidate A's emulator-side cost).
- [ ] Confirm Mesa gfxstream guest driver maturity for the exact protocol
      version the host speaks.

## Gates

- **G1** — standalone harness: iOS app runs MoltenVK + gfxstream host; a
  simulated guest (same process, socket transport) renders a Vulkan triangle
  through the full protocol stack.
- **G2** — that host wired into our QEMU fork's virtio-gpu; guest Mesa
  gfxstream driver renders (`vkcube`, `glxgears` under X/Wayland).
- **G3** — performance bar: in-guest baseline scene ≥ 30 fps sustained;
  fold into DroidDeckOS image. Below bar → document findings, stop.

## Honest ceiling

Even a fully successful track leaves **TCG CPU emulation** as the bottleneck
for modern games: the GPU would no longer be software-rendered, but game
logic still runs on an emulated CPU at a fraction of native speed. Heavy
titles will remain streaming-only regardless.
