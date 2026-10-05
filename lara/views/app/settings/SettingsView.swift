import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum method: String, CaseIterable {
    case vfs = "VFS"
    case sbx = "SBX"
    case hybrid = "Hybrid"
}

enum fmAppsDisplayMode: String, CaseIterable {
    case UUID = "UUID"
    case bundleID = "Bundle ID"
    case appName = "App Name"
}

enum logsdisplaymode: String, CaseIterable {
    case tabs = "In Tabs"
    case toolbar = "In Toolbar"
    case content = "Directly in ContentView"
}

// Existing advanced settings remain in this view.
// The new top-level Settings tab links here instead of duplicating logic.
struct SettingsView: View {
    @EnvironmentObject var mgr: laramgr

    @AppStorage("selectedMethod") private var selectedMethod: method = .hybrid
    @AppStorage("keepAlive") private var keepAlive: Bool = false
    @AppStorage("stashKRW") private var stashKRW: Bool = false
    @AppStorage("keepSpringBoardRemoteCallAliveIOS16") private var keepSpringBoardRemoteCallAliveIOS16: Bool = false
    @AppStorage("logsdisplaymode") private var selectedlogdisplaymode: logsdisplaymode = .toolbar
    @AppStorage("loggerNoBS") private var loggerNoBS: Bool = true
    @AppStorage("showFMInTabs") private var showFMInTabs: Bool = true
    @AppStorage("selectedFMAppsDisplayMode") private var selectedFMAppsDisplayMode: fmAppsDisplayMode = .appName
    @AppStorage("fmRecursiveSearch") private var fmRecursiveSearch: Bool = false
    @AppStorage("rcDockUnlimited") private var rcDockUnlimited: Bool = false

    @State private var dlingkcache = false
    @State private var showkcacheimport = false
    @State private var importingkcache = false
    @State private var showkcachetips = false
    @State private var stashingKRWNow = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink("Credits", destination: CreditsView())
                } header: {
                    HeaderLabel(text: "About", icon: "info.circle")
                }

                Section {
                    Picker("Method", selection: $selectedMethod) {
                        ForEach(method.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    NavigationLink("Modify Offsets", destination: OffsetManagementView())
                } header: {
                    HeaderLabel(text: "Exploit", icon: "ant")
                }

                Section {
                    if !mgr.hasOffsets {
                        Button {
                            fetchKernelcache()
                        } label: {
                            if dlingkcache {
                                HStack {
                                    Text("Fetching Kernelcache…")
                                    Spacer()
                                    ProgressView()
                                }
                            } else {
                                Text("Fetch Kernelcache")
                            }
                        }
                        .disabled(dlingkcache || !mgr.dsready)

                        Button("Import Kernelcache") {
                            showkcacheimport = true
                        }
                        .disabled(dlingkcache || importingkcache)

                        Button("Kernelcache Tips") {
                            showkcachetips.toggle()
                        }
                    } else {
                        Button("Remove Kernelcache") {
                            Alertinator.shared.alert(
                                title: "Clear Kernelcache Data?",
                                body: "This will delete all kernelcache data and remove saved offsets. You will have to refetch the data to use Lara again.",
                                actionLabel: "Confirm",
                                action: clearKcacheData
                            )
                        }
                        .foregroundColor(.red)
                    }

                    if showkcachetips {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Kernelcache tips")
                                .font(.headline)
                            Text("Obtain a kernelcache using the project's documented workflow, then import it above.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    HeaderLabel(text: "Kernelcache", icon: "cpu")
                }

                Section {
                    Toggle("Keep Alive", isOn: $keepAlive)
                        .onChange(of: keepAlive) { _ in
                            if keepAlive {
                                if !kaenabled { toggleka() }
                            } else if kaenabled {
                                toggleka()
                            }
                        }

                    Toggle("Disable Log Dividers", isOn: $loggerNoBS)

                    Picker("Logs Display", selection: $selectedlogdisplaymode) {
                        ForEach(logsdisplaymode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                } header: {
                    HeaderLabel(text: "App", icon: "gearshape")
                }

                Section {
                    Picker("Display Mode", selection: $selectedFMAppsDisplayMode) {
                        ForEach(fmAppsDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    Toggle("Recursive Search in File Manager", isOn: $fmRecursiveSearch)
                    Toggle("Show File Manager in Tabs", isOn: $showFMInTabs)
                } header: {
                    HeaderLabel(text: "File Manager", icon: "folder")
                }

                #if !DISABLE_REMOTECALL
                Section {
                    Toggle("Stash KRW primitives", isOn: $stashKRW)
                        .onChange(of: stashKRW) { enabled in
                            if enabled && isIOS16() {
                                Alertinator.shared.alert(
                                    title: "iOS 16 Warning",
                                    body: "Saving KRW on iOS 16 is currently unstable. If it fails, manually stash KRW a few more times."
                                )
                            }
                        }

                    if isIOS16() {
                        Toggle("Keep SpringBoard RemoteCall alive in background", isOn: $keepSpringBoardRemoteCallAliveIOS16)
                        Text("Warning: If Lara exits while RemoteCall is active, SpringBoard may respring.")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.red)

                        Button {
                            guard !stashingKRWNow else { return }
                            stashingKRWNow = true
                            mgr.stashKRWToLaunchd { success in
                                stashingKRWNow = false
                                if success {
                                    Alertinator.shared.alert(title: "KRW Stashed", body: "KRW primitives were successfully stashed to launchd.", actionLabel: "OK", action: {})
                                } else {
                                    Alertinator.shared.alert(title: "Failed to Stash KRW", body: mgr.rcLastError ?? "Please try again.", actionLabel: "OK")
                                }
                            }
                        } label: {
                            if stashingKRWNow {
                                HStack {
                                    Text("Stashing KRW to launchd…")
                                    Spacer()
                                    ProgressView()
                                }
                            } else {
                                Text("Stash KRW to launchd now")
                            }
                        }
                        .disabled(!mgr.dsready || mgr.rcrunning || stashingKRWNow)
                    }

                    Toggle("Allow >10 dock icons", isOn: $rcDockUnlimited)
                } header: {
                    HeaderLabel(text: "RemoteCall", icon: "syringe")
                }
                #endif
            }
            .navigationTitle("Advanced Settings")
            .fileImporter(isPresented: $showkcacheimport, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importingkcache = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        var ok = false
                        let shouldStopAccess = url.startAccessingSecurityScopedResource()
                        defer {
                            if shouldStopAccess { url.stopAccessingSecurityScopedResource() }
                        }
                        let fm = FileManager.default
                        if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let dest = docs.appendingPathComponent("kernelcache")
                            do {
                                if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
                                try fm.copyItem(at: url, to: dest)
                                ok = dlkcache()
                            } catch {
                                ok = false
                            }
                        }
                        DispatchQueue.main.async {
                            mgr.hasOffsets = ok
                            importingkcache = false
                        }
                    }
                case .failure:
                    break
                }
            }
        }
    }

    private func fetchKernelcache() {
        guard !dlingkcache else { return }
        dlingkcache = true
        DispatchQueue.global(qos: .userInitiated).async {
            let fetched = fetchkcache()
            let loaded = fetched ? dlkcache() : false
            DispatchQueue.main.async {
                mgr.hasOffsets = loaded
                dlingkcache = false
            }
        }
    }

    private func clearKcacheData() {
        let fm = FileManager.default
        UserDefaults.standard.removeObject(forKey: "lara.kernelcache_path")
        UserDefaults.standard.removeObject(forKey: "lara.kernelcache_size")

        if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            let path = docs.appendingPathComponent("kernelcache")
            try? fm.removeItem(at: path)
        }

        for file in ["kernelcache.release.ipad", "kernelcache.release.iphone", "kernelcache.release.ipad3", "kernelcache.release.iphone14,3"] {
            try? fm.removeItem(atPath: NSTemporaryDirectory() + file)
        }

        mgr.logmsg("Kernelcache data cleared")
        mgr.hasOffsets = false
    }
}

struct LaraSettingsTabView: View {
    @EnvironmentObject private var mgr: laramgr
    @AppStorage("selectedMethod") private var selectedMethod: method = .hybrid
    @AppStorage("keepAlive") private var keepAlive: Bool = false
    @AppStorage("loggerNoBS") private var loggerNoBS: Bool = true
    @AppStorage("showFMInTabs") private var showFMInTabs: Bool = true
    @AppStorage("selectedFMAppsDisplayMode") private var selectedFMAppsDisplayMode: fmAppsDisplayMode = .appName
    @AppStorage("fmRecursiveSearch") private var fmRecursiveSearch: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    settingsSection("Exploit") {
                        LaraCard {
                            VStack(spacing: 0) {
                                LaraRow(icon: "bolt.fill", iconColor: .yellow, title: "Exploit Method", subtitle: "How Lara initializes system access") {
                                    Picker("", selection: $selectedMethod) {
                                        ForEach(method.allCases, id: \.self) { method in
                                            Text(method.rawValue).tag(method)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(LaraPalette.accent)
                                }

                                LaraDivider()

                                NavigationLink {
                                    OffsetManagementView()
                                        .environmentObject(mgr)
                                } label: {
                                    LaraRow(icon: "slider.horizontal.3", iconColor: LaraPalette.accent, title: "Modify Offsets", subtitle: "Edit stored kernel offsets") {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(LaraPalette.secondary.opacity(0.55))
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }

                    settingsSection("General") {
                        LaraCard {
                            LaraSettingToggle(icon: "bolt.circle.fill", color: .yellow, title: "Keep Alive", subtitle: "Keep Lara running when minimized", isOn: $keepAlive) {
                                if keepAlive {
                                    if !kaenabled { toggleka() }
                                } else if kaenabled {
                                    toggleka()
                                }
                            }
                            LaraDivider()
                            LaraSettingToggle(icon: "text.line.last.and.arrowtriangle.forward", color: LaraPalette.accent, title: "Compact Logs", subtitle: "Hide divider noise in logs", isOn: $loggerNoBS)
                        }
                    }

                    settingsSection("File Manager") {
                        LaraCard {
                            LaraSettingToggle(icon: "folder.fill", color: LaraPalette.accent, title: "Show Files Tab", subtitle: "Keep File Manager in the main navigation", isOn: $showFMInTabs)
                            LaraDivider()
                            LaraRow(icon: "list.bullet.rectangle", iconColor: .orange, title: "App Folder Display", subtitle: "How installed app folders are named") {
                                Picker("", selection: $selectedFMAppsDisplayMode) {
                                    ForEach(fmAppsDisplayMode.allCases, id: \.self) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(LaraPalette.accent)
                            }
                            LaraDivider()
                            LaraSettingToggle(icon: "magnifyingglass", color: .purple, title: "Recursive Search", subtitle: "Search nested directories", isOn: $fmRecursiveSearch)
                        }
                    }

                    settingsSection("Advanced") {
                        LaraCard {
                            NavigationLink {
                                SettingsView()
                                    .environmentObject(mgr)
                            } label: {
                                LaraRow(icon: "slider.horizontal.3", iconColor: LaraPalette.accent, title: "Advanced Settings", subtitle: "Kernelcache, RemoteCall, logging and app options") {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(LaraPalette.secondary.opacity(0.55))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    settingsSection("About") {
                        LaraCard {
                            NavigationLink {
                                CreditsView()
                            } label: {
                                LaraRow(icon: "person.3.fill", iconColor: .pink, title: "Credits", subtitle: "People and projects behind Lara") {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(LaraPalette.secondary.opacity(0.55))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    Color.clear.frame(height: 18)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(LaraPalette.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            LaraSectionTitle(title)
            content()
        }
    }
}

private struct LaraSettingToggle: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var onChange: (() -> Void)? = nil

    init(icon: String, color: Color, title: String, subtitle: String, isOn: Binding<Bool>, onChange: (() -> Void)? = nil) {
        self.icon = icon
        self.color = color
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.onChange = onChange
    }

    var body: some View {
        LaraRow(icon: icon, iconColor: color, title: title, subtitle: subtitle) {
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    isOn = newValue
                    onChange?()
                }
            ))
            .labelsHidden()
            .tint(LaraPalette.accent)
        }
    }
}
