//
// DroidDeck for iOS
// Copyright (C) 2026 DroidDeck-iOS contributors
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import SwiftUI

/// Host picker + pairing UI for the streaming session (milestone M4).
///
/// Status: discovery is live; the pairing handshake and the Metal/VideoToolbox
/// pipeline land together with the moonlight-common-c integration. See
/// Platform/DroidDeck/Streaming/README.md for the wiring plan.
struct MoonlightSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var discovery = MoonlightDiscovery()
    @State private var pairTarget: MoonlightHost?

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(discovery.hosts) { host in
                        Button {
                            pairTarget = host
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(host.name).font(.headline)
                                Text(host.displayAddress)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("GameStream hosts")
                        Spacer()
                        if discovery.isBrowsing {
                            ProgressView()
                        }
                    }
                } footer: {
                    Text("Runs Sunshine (open source, recommended) or GeForce Experience on your PC. Requires the local-network permission.")
                }
                Section {
                    Text("Pairing and the 60 fps video pipeline are part of milestone M4 (moonlight-common-c integration).")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Stream from your PC")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        discovery.stop()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        discovery.start()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                discovery.start()
            }
            .onDisappear {
                discovery.stop()
            }
            .alert("Pair with \(pairTarget?.name ?? "")?", isPresented: Binding(
                get: { pairTarget != nil },
                set: { if !$0 { pairTarget = nil } }
            )) {
                Button("Pair", role: .none) { /* M4: moonlight-common-c pairing handshake */ }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("A PIN will be shown on the PC; the handshake arrives with the moonlight core integration (M4).")
            }
        }
    }
}
