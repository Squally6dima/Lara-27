import SwiftUI

// Existing PartyUI metrics are intentionally preserved because other UI components
// depend on these names. The Lara palette/components below are presentation-only.

public enum cornerRad {
    public static var component: CGFloat {
        if #available(iOS 19.0, *) { return 18 } else { return 12 }
    }
    public static var platter: CGFloat {
        if #available(iOS 19.0, *) { return 26 } else { return 18 }
    }
    public static var sPlatter: CGFloat {
        if #available(iOS 19.0, *) { return 16 } else { return 12 }
    }
    public static var terminal: CGFloat {
        if #available(iOS 19.0, *) { return 24 } else { return 18 }
    }
}

public enum spacing {
    public static var creditCell: CGFloat {
        if #available(iOS 19.0, *) { return 14 } else { return 16 }
    }
}

public enum width {
    public static var headerIcon: CGFloat {
        if #available(iOS 19.0, *) { return 24 } else { return 22 }
    }
}

public extension EdgeInsets {
    static let sectionInsets = EdgeInsets(top: 6, leading: 15, bottom: 6, trailing: 15)
}

public extension Animation {
    static let iconUpdate = Animation.spring(response: 0.3, dampingFraction: 1.5)
}

// MARK: - Lara visual system

public enum LaraPalette {
    public static let background = Color(red: 0.045, green: 0.045, blue: 0.052)
    public static let card = Color(red: 0.105, green: 0.105, blue: 0.115)
    public static let elevated = Color(red: 0.165, green: 0.165, blue: 0.18)
    public static let accent = Color(red: 0.04, green: 0.52, blue: 1.0)
    public static let primary = Color.white
    public static let secondary = Color(red: 0.56, green: 0.56, blue: 0.59)
    public static let success = Color(red: 0.20, green: 0.78, blue: 0.35)
    public static let warning = Color(red: 1.0, green: 0.62, blue: 0.04)
    public static let destructive = Color(red: 1.0, green: 0.23, blue: 0.19)
    public static let divider = Color.white.opacity(0.075)
    public static let terminal = Color(red: 0.035, green: 0.035, blue: 0.04)
}

public enum LaraMetrics {
    public static let cardRadius: CGFloat = 18
    public static let smallRadius: CGFloat = 12
    public static let horizontalPadding: CGFloat = 16
    public static let rowVerticalPadding: CGFloat = 12
    public static let tabBarHeight: CGFloat = 58
}

public extension Font {
    static let laraLargeTitle = Font.system(size: 34, weight: .bold)
    static let laraCardTitle = Font.system(size: 13, weight: .semibold)
    static let laraBody = Font.system(size: 15)
    static let laraBodySemibold = Font.system(size: 15, weight: .semibold)
    static let laraCaption = Font.system(size: 12)
    static let laraMono = Font.system(size: 12, design: .monospaced)
}

public struct LaraCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .background(LaraPalette.card)
            .clipShape(RoundedRectangle(cornerRadius: LaraMetrics.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LaraMetrics.cardRadius, style: .continuous)
                    .stroke(LaraPalette.divider, lineWidth: 0.5)
            )
    }
}

public struct LaraCardHeader: View {
    let icon: String
    let title: String
    var trailing: AnyView?

    public init(icon: String, title: String, trailing: AnyView? = nil) {
        self.icon = icon
        self.title = title
        self.trailing = trailing
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LaraPalette.accent)
            Text(title.uppercased())
                .font(.laraCardTitle)
                .tracking(0.25)
                .foregroundStyle(LaraPalette.secondary)
            Spacer()
            if let trailing {
                trailing
            }
        }
    }
}

public struct LaraStatusPill: View {
    let title: String
    let color: Color
    var icon: String = "circle.fill"
    var spinning = false

    public init(title: String, color: Color, icon: String = "circle.fill", spinning: Bool = false) {
        self.title = title
        self.color = color
        self.icon = icon
        self.spinning = spinning
    }

    public var body: some View {
        HStack(spacing: 5) {
            if spinning {
                ProgressView()
                    .tint(color)
                    .scaleEffect(0.62)
                    .frame(width: 12, height: 12)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

public struct LaraPrimaryButton: View {
    let title: String
    var icon: String?
    var loading = false
    var disabled = false
    let action: () -> Void

    public init(title: String, icon: String? = nil, loading: Bool = false, disabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.loading = loading
        self.disabled = disabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if loading {
                    ProgressView().tint(.white).scaleEffect(0.78)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title).font(.laraBodySemibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .foregroundStyle(.white.opacity(disabled ? 0.45 : 1))
            .background(LaraPalette.accent.opacity(disabled ? 0.30 : 1))
            .clipShape(RoundedRectangle(cornerRadius: LaraMetrics.smallRadius, style: .continuous))
        }
        .buttonStyle(LaraPressableStyle())
        .disabled(disabled || loading)
    }
}

public struct LaraSecondaryButton: View {
    let title: String
    var icon: String?
    var destructive = false
    var disabled = false
    let action: () -> Void

    public init(title: String, icon: String? = nil, destructive: Bool = false, disabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.destructive = destructive
        self.disabled = disabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 14, weight: .medium))
                }
                Text(title).font(.laraBody)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .foregroundStyle((destructive ? LaraPalette.destructive : LaraPalette.primary).opacity(disabled ? 0.38 : 1))
            .background(LaraPalette.elevated.opacity(disabled ? 0.45 : 1))
            .clipShape(RoundedRectangle(cornerRadius: LaraMetrics.smallRadius, style: .continuous))
        }
        .buttonStyle(LaraPressableStyle())
        .disabled(disabled)
    }
}

public struct LaraRow<Accessory: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String?
    let accessory: Accessory

    public init(icon: String, iconColor: Color = LaraPalette.accent, title: String, subtitle: String? = nil, @ViewBuilder accessory: () -> Accessory) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory()
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(iconColor.opacity(0.14))
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.laraBody).foregroundStyle(LaraPalette.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.laraCaption)
                        .foregroundStyle(LaraPalette.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            accessory
        }
        .padding(.horizontal, LaraMetrics.horizontalPadding)
        .padding(.vertical, LaraMetrics.rowVerticalPadding)
        .contentShape(Rectangle())
    }
}

public struct LaraSectionTitle: View {
    let title: String
    public init(_ title: String) { self.title = title }

    public var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.65)
            .foregroundStyle(LaraPalette.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

public struct LaraDivider: View {
    let inset: CGFloat
    public init(inset: CGFloat = 60) { self.inset = inset }

    public var body: some View {
        Rectangle()
            .fill(LaraPalette.divider)
            .frame(height: 0.5)
            .padding(.leading, inset)
    }
}

public struct LaraPressableStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
    }
}

public struct LaraIconBadge: View {
    let icon: String
    let color: Color

    public init(icon: String, color: Color = LaraPalette.accent) {
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(color.opacity(0.12))
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: 32, height: 32)
    }
}
