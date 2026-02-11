import SwiftUI

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(Theme.sectionHeaderFont)
            .foregroundStyle(Theme.sectionHeaderColor)
            .padding(.vertical, Theme.spacingXS)
    }
}

struct RequiredLabel: View {
    let text: String
    var body: some View {
        HStack(spacing: 2) {
            Text(text)
                .foregroundStyle(Theme.labelColor)
            Text("*")
                .foregroundStyle(.red)
        }
        .font(Theme.labelFont)
    }
}

struct FormRow<Content: View>: View {
    let label: String
    var required: Bool = false
    var help: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            HStack(alignment: .top, spacing: Theme.spacingM) {
                labelView
                    .frame(minWidth: Theme.labelColumnMinWidth, alignment: .leading)
                    .alignmentGuide(.top) { dimension in
                        dimension[.firstTextBaseline]
                    }
                content
                    .font(Theme.valueFont)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            if let help {
                Text(help)
                    .font(.caption)
                    .foregroundStyle(Theme.helpColor)
            }
            Divider()
        }
    }

    @ViewBuilder
    private var labelView: some View {
        if required {
            RequiredLabel(text: label)
        } else {
            Text(label)
                .font(Theme.labelFont)
                .foregroundStyle(Theme.labelColor)
        }
    }
}

struct StatusPill: View {
    let state: CompletionState

    var body: some View {
        Text(label)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
            .foregroundStyle(.black.opacity(0.7))
    }

    private var label: String {
        switch state {
        case .incomplete: return "Incomplete"
        case .complete: return "Complete"
        case .completedWithDeviations: return "Complete w/ deviation"
        }
    }

    private var background: Color {
        switch state {
        case .incomplete: return Theme.statusIncomplete
        case .complete: return Theme.statusComplete
        case .completedWithDeviations: return Theme.statusDeviation
        }
    }
}

struct CompactButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct RadioRow: View {
    let label: String
    let value: String
    @Binding var selection: String
    var isReadOnly: Bool = false

    private var isSelected: Bool { selection == value }

    var body: some View {
        Button {
            selection = value
        } label: {
            HStack(spacing: Theme.spacingS) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 18, weight: .bold))
                Text(label)
                    .foregroundStyle(isReadOnly ? Theme.labelColor.opacity(0.6) : Theme.labelColor)
                Spacer()
            }
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Theme.spacingXS)
        }
        .buttonStyle(.plain)
        .disabled(isReadOnly)
    }
}

struct BannerLogo: View {
    var body: some View {
        Image("BenchCapBanner")
            .resizable()
            .scaledToFit()
            .frame(width: Theme.bannerWidth, height: Theme.bannerHeight, alignment: .trailing)
            .allowsHitTesting(false)
            .padding(.trailing, Theme.spacingS)
    }
}

extension View {
    func entryFieldStyle() -> some View {
        self
            .padding(10)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.entryCornerRadius)
                    .stroke(Theme.entryBorderColor, lineWidth: 1)
            )
    }

    func benchCapBannerToolbar() -> some View {
        toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                BannerLogo()
            }
        }
    }

    func benchCapBannerHeader() -> some View {
        self
    }
}
