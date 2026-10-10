import SwiftUI

enum Palette {
    static let lavender = Color(red: 0.61, green: 0.55, blue: 0.98)
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.69, green: 0.63, blue: 1, alpha: 1)
            : UIColor(red: 0.38, green: 0.29, blue: 0.73, alpha: 1)
    })
    static let midnight = Color(red: 0.035, green: 0.05, blue: 0.10)
    static let darkCard = Color(red: 0.075, green: 0.09, blue: 0.15)
}
struct PageBackground: View {
    @Environment(\.colorScheme) var scheme
    var body: some View { (scheme == .dark ? Palette.midnight : Color(uiColor: .systemGroupedBackground)).ignoresSafeArea() }
}
struct Card<Content: View>: View {
    @Environment(\.colorScheme) var scheme
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(scheme == .dark ? Palette.darkCard : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.primary.opacity(0.05)))
    }
}
struct PrimaryButton: View {
    let title: String
    var icon = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(title); Spacer(); Image(systemName: icon) }
                .font(.headline).padding(.horizontal, 20).padding(.vertical, 17)
                .foregroundStyle(Color(red: 0.045, green: 0.035, blue: 0.12))
                .background(LinearGradient(colors: [Color(red: 0.78, green: 0.74, blue: 1), Palette.lavender], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)
    }
}
struct PreviewBanner: View {
    var body: some View {
        Label("Preview mode · no apps are blocked", systemImage: "viewfinder")
            .font(.caption.weight(.medium)).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading).padding(12)
            .background(Palette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
    }
}
struct Eyebrow: View {
    let text: String
    var body: some View { Text(text.uppercased()).font(.caption.weight(.semibold)).tracking(2).foregroundStyle(.secondary) }
}
extension SelectionCounts {
    var summary: String {
        "\(apps) \(apps == 1 ? "app" : "apps") · \(categories) \(categories == 1 ? "category" : "categories") · \(websites) \(websites == 1 ? "website" : "websites")"
    }
}
func minuteLabel(_ minutes: Int) -> String { minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m" }
