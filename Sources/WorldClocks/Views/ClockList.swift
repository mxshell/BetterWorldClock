import SwiftUI

/// The rows shared by the desktop widget and the menu bar panel.
struct ClockList: View {
    @ObservedObject var store: Store
    let now: Date
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let clocks = Clock.visible(store.cities, at: now)
        let sun = clocks.map { $0.nextSunEvent(after: now) }
        let night = sun.map(\.isNight)
        VStack(spacing: 0) {
            ForEach(Array(clocks.enumerated()), id: \.element.id) { index, clock in
                let nightAbove = index > 0 && night[index - 1]
                let nightBelow = index < clocks.count - 1 && night[index + 1]
                ClockRow(clock: clock, now: now, weather: store.weather[clock.id], sun: sun[index], options: store.display)
                    .background {
                        // Neighbouring night rows join into one band, so the dark side of the world reads at a glance.
                        if night[index] {
                            UnevenRoundedRectangle(topLeadingRadius: nightAbove ? 0 : 12,
                                                   bottomLeadingRadius: nightBelow ? 0 : 12,
                                                   bottomTrailingRadius: nightBelow ? 0 : 12,
                                                   topTrailingRadius: nightAbove ? 0 : 12,
                                                   style: .continuous)
                                .fill(.black.opacity(colorScheme == .dark ? 0.35 : 0.14))
                                .padding(.horizontal, -10)
                        }
                    }
                    .overlay(alignment: .top) {
                        // No divider where a night band starts or ends; its edge already separates the rows.
                        if index > 0, night[index] == night[index - 1] { Divider() }
                    }
            }
            Color.clear.frame(width: 284, height: 0)  // minimum width; the list grows to fit long names
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
    }
}
