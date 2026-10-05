import SwiftUI

enum LaraTab: Hashable, CaseIterable {
    case exploit, tweaks, fileManager, settings

    var title: String {
        switch self {
        case .exploit: return "Exploit"
        case .tweaks: return "Tweaks"
        case .fileManager: return "Files"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .exploit: return "wrench.and.screwdriver.fill"
        case .tweaks: return "ladybug.fill"
        case .fileManager: return "folder.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var mgr: laramgr
    @AppStorage("showFMInTabs") private var showFMInTabs: Bool = true
    @State private var selectedTab: LaraTab = .exploit

    private var tabs: [LaraTab] {
        showFMInTabs ? LaraTab.allCases : [.exploit, .tweaks, .settings]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LaraPalette.background
                .ignoresSafeArea()

            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LaraTabBar(selectedTab: $selectedTab, tabs: tabs)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 5)
        }
        .preferredColorScheme(.dark)
        .onChange(of: showFMInTabs) { visible in
            if !visible, selectedTab == .fileManager {
                selectedTab = .exploit
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .exploit:
            ExploitView(selectedTab: $selectedTab)
        case .tweaks:
            TweaksView(mgr: mgr)
        case .fileManager:
            SantanderView(startPath: "/")
                .background(LaraPalette.background)
        case .settings:
            LaraSettingsTabView()
        }
    }
}

private struct LaraTabBar: View {
    @Binding var selectedTab: LaraTab
    let tabs: [LaraTab]

    @Namespace private var glassNamespace
    @State private var isDragging = false
    @State private var dragStartIndex = 0

    var body: some View {
        GeometryReader { geometry in
            let slotWidth = slotWidth(for: geometry.size.width)

            Group {
                if #available(iOS 26.0, *) {
                    GlassEffectContainer(spacing: 10) {
                        ZStack {
                            // The navigation bar itself is one glass surface.
                            Capsule()
                                .glassEffect(.regular, in: Capsule())
                                .allowsHitTesting(false)

                            tabButtons(slotWidth: slotWidth)
                        }
                    }
                } else {
                    ZStack {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Capsule()
                                    .stroke(Color.white.opacity(0.10), lineWidth: 0.7)
                                    .allowsHitTesting(false)
                            }

                        tabButtons(slotWidth: slotWidth)
                    }
                }
            }
            .padding(7)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Capsule())
            .simultaneousGesture(
                DragGesture(minimumDistance: 6, coordinateSpace: .local)
                    .onChanged { value in
                        guard tabs.count > 1 else { return }

                        if !isDragging {
                            dragStartIndex = tabs.firstIndex(of: selectedTab) ?? 0
                            isDragging = true
                        }

                        let totalWidth = geometry.size.width
                        let usable = max(totalWidth - 14, 1)
                        let step = usable / CGFloat(tabs.count)
                        let raw = CGFloat(dragStartIndex) + (value.translation.width / step)
                        let target = min(
                            max(Int(raw.rounded()), 0),
                            tabs.count - 1
                        )

                        let targetTab = tabs[target]
                        if targetTab != selectedTab {
                            withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.82)) {
                                selectedTab = targetTab
                            }
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: 72)
    }

    @ViewBuilder
    private func tabButtons(slotWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button {
                    withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                } label: {
                    ZStack {
                        // The actual Liquid Glass lens is attached to the selected
                        // control, not to a separate white-filled overlay.
                        if selectedTab == tab {
                            if #available(iOS 26.0, *) {
                                Capsule()
                                    .glassEffect(.clear.interactive(), in: Capsule())
                                    .glassEffectID("selected-tab", in: glassNamespace)
                                    .glassEffectTransition(.matchedGeometry)
                                    .allowsHitTesting(false)
                            } else {
                                Capsule()
                                    .fill(Color.white.opacity(0.13))
                                    .allowsHitTesting(false)
                            }
                        }

                        Image(systemName: tab.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(
                                selectedTab == tab
                                    ? LaraPalette.accent
                                    : LaraPalette.primary.opacity(0.96)
                            )
                    }
                    .frame(width: slotWidth, height: 58)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
            }
        }
        .padding(.horizontal, 7)
    }

    private func slotWidth(for totalWidth: CGFloat) -> CGFloat {
        let usable = max(totalWidth - 14, 1)
        return usable / CGFloat(max(tabs.count, 1))
    }
}

struct ExploitView: View {
    @EnvironmentObject private var mgr: laramgr
    @Binding var selectedTab: LaraTab
    @AppStorage("selectedMethod") private var selectedMethod: method = .hybrid
    @State private var fetchingKernelcache = false
    @State private var showPanicAlert = false

    private var kernelStatusTitle: String {
        if mgr.dsrunning { return "Running" }
        if mgr.dsready { return "Active" }
        if mgr.hasOffsets { return "Offsets loaded" }
        return "Not ready"
    }

    private var kernelStatusColor: Color {
        if mgr.dsrunning { return LaraPalette.warning }
        if mgr.dsready { return LaraPalette.success }
        if mgr.hasOffsets { return LaraPalette.accent }
        return LaraPalette.secondary
    }

    private var systemReady: Bool {
        switch selectedMethod {
        case .hybrid: return mgr.vfsready && mgr.sbxready
        case .vfs: return mgr.vfsready
        case .sbx: return mgr.sbxready
        }
    }

    private var systemStatus: String {
        switch selectedMethod {
        case .hybrid:
            if mgr.vfsready && mgr.sbxready { return "System ready" }
            if mgr.vfsrunning || mgr.sbxrunning { return "Initializing" }
            return "Not initialized"
        case .vfs:
            if mgr.vfsready { return "VFS ready" }
            if mgr.vfsrunning { return "Initializing" }
            return "Not initialized"
        case .sbx:
            if mgr.sbxready { return "Sandbox ready" }
            if mgr.sbxrunning { return "Initializing" }
            return "Not initialized"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if !mgr.hasOffsets {
                        LaraCard {
                            HStack(alignment: .top, spacing: 12) {
                                LaraIconBadge(icon: "exclamationmark.triangle.fill", color: LaraPalette.warning)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Kernelcache offsets missing")
                                        .font(.laraBodySemibold)
                                        .foregroundStyle(LaraPalette.primary)
                                    Text("Run the exploit, then fetch the kernelcache if offsets are unavailable.")
                                        .font(.laraCaption)
                                        .foregroundStyle(LaraPalette.secondary)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(14)
                        }
                    }

                    LaraCard {
                        VStack(alignment: .leading, spacing: 0) {
                            LaraCardHeader(
                                icon: "cpu.fill",
                                title: "Kernel / Exploit",
                                trailing: AnyView(
                                    LaraStatusPill(
                                        title: kernelStatusTitle,
                                        color: kernelStatusColor,
                                        icon: mgr.dsready ? "checkmark.circle.fill" : "circle.fill",
                                        spinning: mgr.dsrunning
                                    )
                                )
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 14)

                            VStack(spacing: 8) {
                                LaraPrimaryButton(
                                    title: mgr.dsrunning ? "Running Exploit…" : "Run Exploit",
                                    icon: "bolt.fill",
                                    loading: mgr.dsrunning,
                                    disabled: mgr.dsrunning || mgr.dsready || isdebugged()
                                ) {
                                    offsets_init()
                                    mgr.run()
                                }

                                LaraSecondaryButton(
                                    title: fetchingKernelcache ? "Fetching Kernelcache…" : "Fetch Kernelcache",
                                    icon: "arrow.down.circle",
                                    disabled: fetchingKernelcache || !mgr.dsready
                                ) {
                                    fetchKernelcache()
                                }
                            }
                            .padding(16)

                            if mgr.dsrunning {
                                ProgressView(value: mgr.dsprogress)
                                    .tint(LaraPalette.accent)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 14)
                            }
                        }
                    }

                    LaraCard {
                        VStack(alignment: .leading, spacing: 0) {
                            LaraCardHeader(
                                icon: "externaldrive.fill",
                                title: "System Access",
                                trailing: AnyView(
                                    LaraStatusPill(
                                        title: systemStatus,
                                        color: systemReady ? LaraPalette.success : (mgr.vfsrunning || mgr.sbxrunning ? LaraPalette.warning : LaraPalette.secondary),
                                        icon: systemReady ? "checkmark.circle.fill" : "circle.fill",
                                        spinning: mgr.vfsrunning || mgr.sbxrunning
                                    )
                                )
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 14)

                            VStack(spacing: 8) {
                                LaraPrimaryButton(
                                    title: selectedMethod == .hybrid ? "Initialize System" : selectedMethod == .vfs ? "Initialize VFS" : "Escape Sandbox",
                                    icon: "play.fill",
                                    loading: mgr.vfsrunning || mgr.sbxrunning,
                                    disabled: !mgr.dsready || !mgr.hasOffsets || systemReady || mgr.vfsrunning || mgr.sbxrunning || isdebugged()
                                ) {
                                    initializeSystem()
                                }

                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(LaraPalette.secondary)
                                    Text("Mode: \(selectedMethod.rawValue). Change it in Settings.")
                                        .font(.laraCaption)
                                        .foregroundStyle(LaraPalette.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 2)
                            }
                            .padding(16)
                        }
                    }

                    #if !DISABLE_REMOTECALL
                    LaraCard {
                        VStack(alignment: .leading, spacing: 0) {
                            LaraCardHeader(
                                icon: "network",
                                title: "RemoteCall",
                                trailing: AnyView(
                                    LaraStatusPill(
                                        title: mgr.rcready ? "Active" : (mgr.rcrunning ? "Running" : "Inactive"),
                                        color: mgr.rcready ? LaraPalette.success : (mgr.rcrunning ? LaraPalette.warning : LaraPalette.secondary),
                                        icon: mgr.rcready ? "checkmark.circle.fill" : "circle.fill",
                                        spinning: mgr.rcrunning
                                    )
                                )
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 14)

                            VStack(spacing: 8) {
                                LaraPrimaryButton(
                                    title: mgr.rcready ? "RemoteCall Active" : "Initialize RemoteCall",
                                    icon: mgr.rcready ? "checkmark.circle.fill" : "play.fill",
                                    disabled: !mgr.dsready || mgr.rcrunning || mgr.rcready || isdebugged()
                                ) {
                                    mgr.rcinit(process: "SpringBoard", migbypass: false) { success in
                                        if success {
                                            mgr.logmsg("rc init succeeded!")
                                            let pid = mgr.rccall(name: "getpid")
                                            mgr.logmsg("remote getpid() returned: \(pid)")
                                        } else {
                                            mgr.logmsg("rc init failed")
                                            mgr.rcfailed = true
                                        }
                                    }
                                }

                                if mgr.rcready {
                                    LaraSecondaryButton(
                                        title: "Destroy RemoteCall",
                                        icon: "xmark.circle",
                                        destructive: true
                                    ) {
                                        mgr.rcdestroy()
                                    }
                                }

                                if let error = mgr.rcLastError, !error.isEmpty {
                                    Text(error)
                                        .font(.laraCaption)
                                        .foregroundStyle(LaraPalette.destructive)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                Text("RemoteCall is relatively unstable and may not work properly.")
                                    .font(.laraCaption)
                                    .foregroundStyle(LaraPalette.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                        }
                    }
                    #endif

                    LaraCard {
                        VStack(alignment: .leading, spacing: 0) {
                            LaraCardHeader(icon: "wrench.and.screwdriver.fill", title: "Actions")
                                .padding(.horizontal, 16)
                                .padding(.top, 14)

                            Button {
                                mgr.respring()
                            } label: {
                                LaraRow(icon: "arrow.counterclockwise", iconColor: LaraPalette.accent, title: "Respring", subtitle: "Restart SpringBoard") {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(LaraPalette.secondary.opacity(0.5))
                                }
                            }
                            .buttonStyle(LaraPressableStyle())

                            LaraDivider()

                            Button {
                                showPanicAlert = true
                            } label: {
                                LaraRow(icon: "bolt.trianglebadge.exclamationmark", iconColor: LaraPalette.destructive, title: "Panic", subtitle: "Force a kernel panic and restart the device") {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(LaraPalette.secondary.opacity(0.5))
                                }
                            }
                            .buttonStyle(LaraPressableStyle())
                        }
                        .padding(.bottom, 3)
                    }

                    #if DEBUG
                    if weonadebugbuild_pjbweouttahereexclamationmark && mgr.dsready {
                        LaraCard {
                            VStack(alignment: .leading, spacing: 10) {
                                LaraCardHeader(icon: "ladybug.fill", title: "Debug")
                                HStack {
                                    Text("kernel_base")
                                    Spacer()
                                    Text(String(format: "0x%llx", mgr.kernbase))
                                }
                                HStack {
                                    Text("kernel_slide")
                                    Spacer()
                                    Text(String(format: "0x%llx", mgr.kernslide))
                                }
                            }
                            .font(.laraMono)
                            .foregroundStyle(LaraPalette.secondary)
                            .padding(16)
                        }
                    }
                    #endif

                    Color.clear.frame(height: 18)
                }
                .padding(.horizontal, LaraMetrics.horizontalPadding)
                .padding(.top, 8)
            }
            .background(LaraPalette.background)
            .navigationTitle("lara")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        mgr.showLogs = true
                    } label: {
                        Image(systemName: "terminal")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .accessibilityLabel("Open logs")
                }
            }
        }
        .alert("Force Kernel Panic", isPresented: $showPanicAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Panic", role: .destructive) {
                mgr.panic()
            }
        } message: {
            Text("This will immediately force a kernel panic. Your device will restart.")
        }
    }

    private func initializeSystem() {
        switch selectedMethod {
        case .hybrid:
            mgr.vfsinit()
            mgr.sbxescape()
        case .vfs:
            mgr.vfsinit()
        case .sbx:
            mgr.sbxescape()
        }
    }

    private func fetchKernelcache() {
        guard !fetchingKernelcache else { return }
        fetchingKernelcache = true

        DispatchQueue.global(qos: .userInitiated).async {
            let fetched = fetchkcache()
            let loaded = fetched ? dlkcache() : false
            DispatchQueue.main.async {
                mgr.hasOffsets = loaded
                fetchingKernelcache = false
            }
        }
    }
}
