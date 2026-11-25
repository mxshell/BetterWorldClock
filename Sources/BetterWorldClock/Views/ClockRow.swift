import SwiftUI

struct ClockRow: View {
    let clock: Clock
    let now: Date
    let weather: Weather?
    let sun: SunEvent
    let options: DisplayOptions
    /// What every row shows in its columns, so each row can make its columns just as wide.
    var columns = DetailColumns()

    private var unit: TemperatureUnit { options.unit }
    private var showsDetails: Bool { options.showWeather || options.showSun }

    var body: some View {
        HStack(spacing: 10) {
            offsetLabel
            switch clock {
            case .city(let city): cityContent(city)
            case .utc: utcContent
            }
        }
        .padding(.vertical, 7)
    }

    /// "UTC−8", turned on its side in a narrow column at the left edge.
    private var offsetLabel: some View {
        Sideways {
            Text(clock.timeZone.utcOffsetText(for: now))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .fixedSize()
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 13)
    }

    private func cityContent(_ city: City) -> some View {
        // With nothing under the time, centre it like the UTC row instead of dropping it to the last line.
        HStack(alignment: showsDetails ? .lastTextBaseline : .center) {
            VStack(alignment: .leading, spacing: 1) {
                title(city.name, isLocal: city.isLocal)
                dateText
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(clock.timeZone.fullName(for: now))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if clock.timeZone.isDaylightSavingTime(for: now) {
                        Text("DST")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.orange.opacity(0.18), in: Capsule())
                    }
                }
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 1) {
                timeText
                if showsDetails {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        if options.showWeather { conditions }
                        if options.showSun { sunDetail }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                    .fixedSize()
                }
            }
        }
    }

    /// Two lines centred in a slot as tall as a city row, so every row is the same height.
    private var utcContent: some View {
        ZStack {
            cityContent(City(name: "UTC", country: "", timeZoneID: "UTC", latitude: 0, longitude: 0))
                .fixedSize()
                .frame(width: 0)  // lends its height, not its width
                .hidden()
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    title("UTC", isLocal: false)
                    dateText
                }
                Spacer(minLength: 12)
                timeText
            }
        }
    }

    private func title(_ name: String, isLocal: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
            if isLocal {
                Image(systemName: "location.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dateText: some View {
        Text(dateLine)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    /// "21:05", or "9:05 PM" in 12-hour mode.
    private var timeText: some View {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = clock.timeZone
        calendar.locale = .current
        let c = calendar.dateComponents([.hour, .minute], from: now)
        let hour = c.hour ?? 0, minute = c.minute ?? 0
        return HStack(alignment: .firstTextBaseline, spacing: 3) {
            Group {
                if options.timeFormat == .h24 {
                    Text(String(format: "%02d:%02d", hour, minute))
                } else {
                    Text(String(format: "%d:%02d", hour % 12 == 0 ? 12 : hour % 12, minute))
                }
            }
            .font(.system(size: 26, weight: .semibold, design: .rounded))
            .monospacedDigit()
            if options.timeFormat == .h12 {
                // As wide as the wider of AM/PM, so the minutes stay in one column.
                ZStack(alignment: .trailing) {
                    Text(calendar.amSymbol).hidden()
                    Text(calendar.pmSymbol).hidden()
                    Text(hour < 12 ? calendar.amSymbol : calendar.pmSymbol)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            }
        }
    }

    /// "Sun, Nov 1 · +15h" — weekday and date there, plus the offset from here.
    private var dateLine: String {
        let date = now.formatted(Date.FormatStyle(timeZone: clock.timeZone).weekday(.abbreviated).month(.abbreviated).day())
        let offset = clock.timeZone.secondsFromGMT(for: now) - TimeZone.autoupdatingCurrent.secondsFromGMT(for: now)
        if case .city(let city) = clock, city.isLocal { return date }
        guard offset != 0 else { return date }
        let sign = offset > 0 ? "+" : "−"
        let hours = abs(offset) / 3600, minutes = abs(offset) % 3600 / 60
        return "\(date) · \(sign)\(hours)\(minutes == 0 ? "" : String(format: ":%02d", minutes))h"
    }

    // Weather and sun details sit in fixed-width columns so icons and values line up across rows.
    fileprivate static let iconWidth: CGFloat = 18


    /// The weather, with day or night taken from the sun calculation. The forecast's own day/night flag is as
    /// old as the last fetch, so the icon could show a sun for up to two hours after sunset.
    private var currentWeather: Weather? {
        guard var weather else { return nil }
        weather.isDay = !sun.isNight
        return weather
    }

    @ViewBuilder private var conditions: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if let weather = currentWeather {
                let colors = weather.palette
                Image(systemName: weather.symbolName)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(colors.0, colors.1, colors.2)
                    .modifier(IconSlot())
                column(unit.format(weather.temperature), widths: columns.temperatures)
            } else {
                Color.clear.frame(width: Self.iconWidth, height: 1)
                column("—", widths: columns.temperatures).foregroundStyle(.tertiary)
            }
        }
        .opacity(weather?.isStale == true ? 0.45 : 1)
    }

    /// Countdown to the next sunrise or sunset there: "☀︎↑ in 10h 38m".
    @ViewBuilder private var sunDetail: some View {
        switch sun {
        case .sunrise: sunLabel("sun.horizon", rising: true)
        case .sunset: sunLabel("sun.horizon", rising: false)
        case .polarDay: sunLabel("sun.max", rising: nil)
        case .polarNight: sunLabel("moon", rising: nil)
        }
    }

    /// An outline sun on the horizon, an arrow for rising or setting, then the countdown.
    /// The sun and "in" use the secondary text colour, which always stands out from the glass behind,
    /// whatever the wallpaper. Only the arrow is coloured (orange up, pink down), deepened toward the text colour.
    private func sunLabel(_ symbol: String, rising: Bool?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Image(systemName: symbol)
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)
                    .modifier(IconSlot())
                Group {
                    if let rising {
                        Image(systemName: rising ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle((rising ? Color.orange : .pink).mix(with: .primary, by: 0.2))
                    } else {
                        Color.clear.frame(height: 1)
                    }
                }
                .frame(width: 8)
            }
            // "in" sits right after the arrow and the countdown is right-aligned after it, so the gap after
            // the arrow never changes and hours and minutes line up from row to row.
            ZStack(alignment: .trailing) {
                ForEach(Array(Set(columns.polarLabels)).sorted(), id: \.self) { Text($0).hidden() }
                inCountdown("").hidden()  // polar rows keep the same width as the others
                if let label = sun.polarLabel {
                    Text(label).foregroundStyle(.secondary)
                } else {
                    inCountdown(sun.countdown(from: now) ?? "")
                }
            }
            .fixedSize()
        }
    }

    private func inCountdown(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text("in").foregroundStyle(.secondary)
            column(text, widths: columns.countdowns)
        }
    }

    /// Right-aligned text as wide as the widest of `widths` (and itself), so values form a column.
    private func column(_ text: String, widths: [String]) -> some View {
        ZStack(alignment: .trailing) {
            ForEach(Array(Set(widths)).sorted(), id: \.self) { Text($0).hidden() }
            Text(text)
        }
        .lineLimit(1)
        .fixedSize()
    }
}

/// The values shown in the shared columns across all rows; each row sizes its columns to the widest.
struct DetailColumns {
    var temperatures: [String] = []
    var countdowns: [String] = []
    var polarLabels: [String] = []
}

extension SunEvent {
    /// "10h 38m" or "45m" until the sunrise or sunset; nil for polar day and night.
    func countdown(from now: Date) -> String? {
        switch self {
        case .sunrise(let date), .sunset(let date):
            let minutes = max(0, Int(date.timeIntervalSince(now) / 60))
            return minutes >= 60 ? "\(minutes / 60)h \(String(format: "%02d", minutes % 60))m" : "\(minutes)m"
        case .polarDay, .polarNight:
            return nil
        }
    }

    var polarLabel: String? {
        switch self {
        case .polarDay: "polar day"
        case .polarNight: "polar night"
        case .sunrise, .sunset: nil
        }
    }
}

/// A fixed box for a weather or sun symbol, centred on the text's cap height. Symbols differ in size and
/// baseline, so without this the rows would differ in height by a point or two.
private struct IconSlot: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: ClockRow.iconWidth, height: 15)
            .alignmentGuide(.firstTextBaseline) { $0.height / 2 + 4.3 }
            .alignmentGuide(.lastTextBaseline) { $0.height / 2 + 4.3 }
    }
}

/// Gives its content a sideways frame (width and height swapped); pair with a ±90° rotationEffect.
private struct Sideways: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let size = subviews.first?.sizeThatFits(.unspecified) ?? .zero
        return CGSize(width: size.height, height: size.width)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center, proposal: .unspecified)
    }
}

private extension Weather {
    /// Symbol layer colors that stay legible on light and dark glass (clouds first, then sun/moon/precipitation).
    var palette: (AnyShapeStyle, AnyShapeStyle, AnyShapeStyle) {
        let cloud = AnyShapeStyle(.secondary)
        let sun = AnyShapeStyle(Color.yellow)
        let moon = AnyShapeStyle(.primary)
        switch code {
        case 0: return isDay ? (sun, sun, sun) : (moon, cloud, cloud)
        case 1, 2: return (cloud, isDay ? sun : moon, cloud)
        case 51...67, 80...82: return (cloud, AnyShapeStyle(Color.blue), cloud)
        case 71...77, 85, 86: return (cloud, AnyShapeStyle(Color.cyan), cloud)
        case 95...99: return (cloud, sun, AnyShapeStyle(Color.blue))
        default: return (cloud, cloud, cloud)
        }
    }
}
