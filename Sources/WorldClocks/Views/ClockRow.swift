import SwiftUI

struct ClockRow: View {
    let clock: Clock
    let now: Date
    let weather: Weather?
    let sun: SunEvent
    let options: DisplayOptions

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
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
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

    /// Widest plausible reading: -40…99 °C or -99…120 °F.
    private var temperatureTemplate: String { unit == .celsius ? "-00°C" : "000°F" }

    @ViewBuilder private var conditions: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if let weather {
                let colors = weather.palette
                Image(systemName: weather.symbolName)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(colors.0, colors.1, colors.2)
                    .modifier(IconSlot())
                column(unit.format(weather.temperature), template: temperatureTemplate)
            } else {
                Color.clear.frame(width: Self.iconWidth, height: 1)
                column("—", template: temperatureTemplate).foregroundStyle(.tertiary)
            }
        }
        .opacity(weather?.isStale == true ? 0.45 : 1)
    }

    /// Countdown to the next sunrise or sunset there.
    @ViewBuilder private var sunDetail: some View {
        switch sun {
        case .sunrise(let date): sunLabel("sunrise.fill", .orange, countdown(to: date))
        case .sunset(let date): sunLabel("sunset.fill", .pink, countdown(to: date))
        case .polarDay: sunLabel("sun.max.fill", .orange, "polar")
        case .polarNight: sunLabel("moon.fill", .indigo, "polar")
        }
    }

    /// The arrow and horizon use the secondary text colour, which always stands out from the glass behind,
    /// whatever the wallpaper. Only the sun carries colour, deepened slightly toward the text colour.
    /// (A fixed faded colour was the same brightness as grey glass over a dark wallpaper and vanished.)
    /// Single-layer symbols (the polar sun and moon) take the colour as a whole.
    private func sunLabel(_ symbol: String, _ color: Color, _ text: String) -> some View {
        let tint = AnyShapeStyle(color.mix(with: .primary, by: 0.2))
        return HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: symbol)
                .symbolRenderingMode(.palette)
                .foregroundStyle(symbol.hasPrefix("sunrise") || symbol.hasPrefix("sunset") ? AnyShapeStyle(.secondary) : tint,
                                 tint, AnyShapeStyle(.secondary))
                .fontWeight(.semibold)
                .modifier(IconSlot())
            column(text, template: "00h 00m")
        }
    }

    /// Right-aligned text as wide as `template`, so values form a column.
    private func column(_ text: String, template: String) -> some View {
        Text(template)
            .fixedSize()
            .hidden()
            .overlay(alignment: .trailing) { Text(text).lineLimit(1).fixedSize() }
    }

    private func countdown(to date: Date) -> String {
        let minutes = max(0, Int(date.timeIntervalSince(now) / 60))
        return minutes >= 60 ? "\(minutes / 60)h \(String(format: "%02d", minutes % 60))m" : "\(minutes)m"
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
