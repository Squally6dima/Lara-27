import SwiftUI

struct TweaksView: View {
    @ObservedObject var mgr: laramgr

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    if !mgr.dsready {
                        LaraCard {
                            HStack(alignment: .top, spacing: 12) {
                                LaraIconBadge(icon: "lock.fill", color: LaraPalette.warning)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Exploit required")
                                        .font(.laraBodySemibold)
                                        .foregroundStyle(LaraPalette.primary)
                                    Text("Run the exploit from the Exploit tab before applying tweaks.")
                                        .font(.laraCaption)
                                        .foregroundStyle(LaraPalette.secondary)
                                }
                            }
                            .padding(14)
                        }
                    }

                    tweakSection("SpringBoard") {
                        LaraCard {
                            tweakLink("network", LaraPalette.accent, "RemoteCall Customizer", "RemoteCall-based SpringBoard tweaks") { RemoteView(mgr: mgr) }
                                .disabled(!mgr.rcready)
                            LaraDivider()
                            tweakLink("wand.and.stars", .purple, "Liquid Glass", "Customize glass appearance") { LiquidGlassView() }
                                .disabled(!mgr.vfsready)
                            LaraDivider()
                            tweakLink("square.grid.2x2.fill", .orange, "SpringBoard Customizer", "Layout and icon behavior") { SpringBoardView(mgr: mgr) }
                                .disabled(!mgr.vfsready)
                        }
                    }

                    tweakSection("Lock Screen") {
                        LaraCard {
                            tweakLink("lock.fill", .orange, "Passcode Theme", "Customize the lock screen passcode UI") { PasscodeView(mgr: mgr) }
                                .disabled(!mgr.sbxready)
                        }
                    }

                    tweakSection("Apps") {
                        LaraCard {
                            tweakLink("rectangle.stack.fill", LaraPalette.accent, "Card Overwrite", "Replace app card assets") { CardView() }
                                .disabled(!mgr.vfsready)
                            LaraDivider()
                            tweakLink("lock.open.fill", .green, "App Decrypt", "Decrypt installed applications") { DecryptView() }
                                .disabled(!mgr.sbxready)
                            LaraDivider()
                            tweakLink("app.badge.fill", .green, "3 App Bypass", "Bypass the sideloaded app limit") { AppsView() }
                                .disabled(!mgr.sbxready)
                            LaraDivider()
                            tweakLink("checkmark.shield.fill", .orange, "Unblacklist", "Manage application blacklist state") { WhitelistView() }
                                .disabled(!mgr.sbxready)
                            LaraDivider()
                            tweakLink("bolt.circle.fill", .yellow, "JIT Enabler", "Enable JIT for supported apps") { JitView() }
                                .disabled(!mgr.sbxready)
                        }
                    }

                    tweakSection("Appearance") {
                        LaraCard {
                            tweakLink("eye.slash.fill", LaraPalette.accent, "Show Hidden Icons", "Reveal hidden SpringBoard icons") { ShowHiddenIconsView(mgr: mgr) }
                                .disabled(!mgr.sbxready && !mgr.vfsready)
                            LaraDivider()
                            tweakLink("textformat", .pink, "Font Overwrite", "Replace system font assets") { FontPicker(mgr: mgr) }
                                .disabled(!mgr.vfsready)
                            LaraDivider()
                            tweakLink("paintpalette.fill", .cyan, "SystemColor Patcher", "Patch system accent colors") { SystemColor(mgr: mgr) }
                                .disabled(!mgr.sbxready || !mgr.vfsready)
                            LaraDivider()
                            tweakLink("cpu.fill", .purple, "MobileGestalt", "Edit system capability values") { GestaltView(mgr: mgr) }
                                .disabled(!mgr.sbxready)
                        }
                    }

                    tweakSection("System") {
                        LaraCard {
                            tweakLink("trash.fill", .orange, "VarClean", "Clean supported system data") { VarCleanView() }
                                .disabled(!mgr.sbxready)
                            LaraDivider()
                            tweakLink("doc.badge.gearshape", LaraPalette.accent, "Custom Overwrite", "Replace arbitrary supported files") { CustomView(mgr: mgr) }
                                .disabled(!mgr.vfsready)
                            LaraDivider()
                            tweakLink("arrow.down.to.line", .orange, "OTA Updates", "Disable over-the-air updates") { OTAView(mgr: mgr) }
                            LaraDivider()
                            tweakLink("hourglass", .pink, "Screen Time", "Disable Screen Time restrictions") { ScreenTimeView(mgr: mgr) }
                        }
                    }

                    tweakSection("Advanced") {
                        LaraCard {
                            tweakLink("0.circle.fill", LaraPalette.destructive, "dirtyZero", "Advanced kernel memory experiment") { dirtyZeroView() }
                                .disabled(!mgr.vfsready)
                            LaraDivider()
                            tweakLink("wrench.and.screwdriver.fill", LaraPalette.accent, "Extra Tools", "Developer and diagnostic utilities") { ToolsView() }
                        }
                    }

                    tweakSection("Unavailable") {
                        LaraCard {
                            LaraRow(icon: "exclamationmark.triangle.fill", iconColor: LaraPalette.warning, title: "DarkBoard", subtitle: "Currently unavailable") {
                                Text("Unavailable")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(LaraPalette.secondary)
                            }
                        }
                    }

                    Color.clear.frame(height: 18)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(LaraPalette.background)
            .navigationTitle("Tweaks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        mgr.showLogs = true
                    } label: {
                        Image(systemName: "terminal")
                            .foregroundStyle(LaraPalette.accent)
                    }
                    .accessibilityLabel("Open logs")
                }
            }
        }
        .preferredColorScheme(.dark)
        .disabled(!mgr.dsready)
    }

    @ViewBuilder
    private func tweakSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            LaraSectionTitle(title)
            content()
        }
    }

    private func tweakLink<Destination: View>(
        _ icon: String,
        _ color: Color,
        _ title: String,
        _ subtitle: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            LaraRow(icon: icon, iconColor: color, title: title, subtitle: subtitle) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LaraPalette.secondary.opacity(0.55))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}