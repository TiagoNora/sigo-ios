import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    private let isoFormatter = ISO8601DateFormatter()
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            title: NSLocalizedString("widget_title", comment: "Widget title"),
            acknowledged: 0,
            held: 0,
            inProgress: 0,
            pending: 0,
            total: 0,
            lastUpdate: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let data = UserDefaults.init(suiteName: "group.com.alticelabs.sigo.onecare")
        let entry = SimpleEntry(
            date: Date(),
            title: NSLocalizedString("widget_title", comment: "Widget title"),
            acknowledged: data?.integer(forKey: "ticket_acknowledged") ?? 0,
            held: data?.integer(forKey: "ticket_held") ?? 0,
            inProgress: data?.integer(forKey: "ticket_in_progress") ?? 0,
            pending: data?.integer(forKey: "ticket_pending") ?? 0,
            total: data?.integer(forKey: "ticket_total") ?? 0,
            lastUpdate: parseDate(data?.string(forKey: "ticket_last_update"))
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let data = UserDefaults.init(suiteName: "group.com.alticelabs.sigo.onecare")
        let entry = SimpleEntry(
            date: Date(),
            title: NSLocalizedString("widget_title", comment: "Widget title"),
            acknowledged: data?.integer(forKey: "ticket_acknowledged") ?? 0,
            held: data?.integer(forKey: "ticket_held") ?? 0,
            inProgress: data?.integer(forKey: "ticket_in_progress") ?? 0,
            pending: data?.integer(forKey: "ticket_pending") ?? 0,
            total: data?.integer(forKey: "ticket_total") ?? 0,
            lastUpdate: parseDate(data?.string(forKey: "ticket_last_update"))
        )

        // Reload timeline every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        return isoFormatter.date(from: value)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let title: String
    let acknowledged: Int
    let held: Int
    let inProgress: Int
    let pending: Int
    let total: Int
    let lastUpdate: Date?
}

struct SigoWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.locale) var locale

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.13, green: 0.59, blue: 0.95), Color(red: 0.10, green: 0.46, blue: 0.82)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 20, height: 20)
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    }

                    Text(entry.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Link(destination: URL(string: "com.alticelabs.sigo.onecare://refresh")!) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel(Text(NSLocalizedString("widget_refresh", comment: "Reload")))
                }

                // Chart and Legend
                HStack(spacing: 12) {
                    // Donut Chart
                    DonutChartView(
                        acknowledged: entry.acknowledged,
                        held: entry.held,
                        inProgress: entry.inProgress,
                        pending: entry.pending
                    )
                    .frame(width: 80, height: 80)

                    // Legend
                    VStack(alignment: .leading, spacing: 4) {
                        LegendItem(color: Color(red: 0.13, green: 0.59, blue: 0.95), label: NSLocalizedString("widget_acknowledged", comment: "Acknowledged"), count: entry.acknowledged)
                        LegendItem(color: Color(red: 1.0, green: 0.6, blue: 0.0), label: NSLocalizedString("widget_held", comment: "Held"), count: entry.held)
                        LegendItem(color: Color(red: 0.3, green: 0.69, blue: 0.31), label: NSLocalizedString("widget_in_progress", comment: "In progress"), count: entry.inProgress)
                        LegendItem(color: Color(red: 0.96, green: 0.26, blue: 0.21), label: NSLocalizedString("widget_pending", comment: "Pending"), count: entry.pending)
                    }
                    .font(.system(size: 9))
                }

                // Total and Last Update
                HStack {
                    Text(String(format: NSLocalizedString("widget_total_format", comment: "Total tickets"), entry.total))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(lastUpdateText)
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
            }
            .padding(10)
        }
        .widgetURL(URL(string: "com.alticelabs.sigo.onecare://home"))
    }

    private var lastUpdateText: String {
        guard let date = entry.lastUpdate else {
            return NSLocalizedString("widget_last_update_default", comment: "Last update default")
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return String(
            format: NSLocalizedString("widget_last_update_format", comment: "Last update format"),
            formatter.string(from: date)
        )
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            Text("\(count)")
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
    }
}

struct DonutChartView: View {
    let acknowledged: Int
    let held: Int
    let inProgress: Int
    let pending: Int

    var total: Int {
        acknowledged + held + inProgress + pending
    }

    var body: some View {
        ZStack {
            if total > 0 {
                // Draw donut segments
                DonutSegment(
                    startAngle: -90,
                    amount: Double(acknowledged),
                    total: Double(total),
                    color: Color(red: 0.13, green: 0.59, blue: 0.95)
                )

                DonutSegment(
                    startAngle: -90 + (360.0 * Double(acknowledged) / Double(total)),
                    amount: Double(held),
                    total: Double(total),
                    color: Color(red: 1.0, green: 0.6, blue: 0.0)
                )

                DonutSegment(
                    startAngle: -90 + (360.0 * Double(acknowledged + held) / Double(total)),
                    amount: Double(inProgress),
                    total: Double(total),
                    color: Color(red: 0.3, green: 0.69, blue: 0.31)
                )

                DonutSegment(
                    startAngle: -90 + (360.0 * Double(acknowledged + held + inProgress) / Double(total)),
                    amount: Double(pending),
                    total: Double(total),
                    color: Color(red: 0.96, green: 0.26, blue: 0.21)
                )

                // Center circle with total
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 45, height: 45)

                Text("\(total)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.13, green: 0.59, blue: 0.95))
            } else {
                // Empty state
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 12)

                Text(NSLocalizedString("widget_no_data", comment: "No data"))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

struct DonutSegment: View {
    let startAngle: Double
    let amount: Double
    let total: Double
    let color: Color

    var endAngle: Double {
        startAngle + (360.0 * amount / total)
    }

    var body: some View {
        Circle()
            .trim(from: 0, to: 1)
            .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
            .rotationEffect(.degrees(startAngle))
            .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
            .mask(
                Circle()
                    .trim(from: startAngle / 360, to: endAngle / 360)
                    .stroke(Color.white, lineWidth: 14)
            )
    }
}

@main
struct SigoWidget: Widget {
    let kind: String = "SigoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SigoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("widget_display_name", comment: "Widget display name"))
        .description(NSLocalizedString("widget_description", comment: "Widget description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SigoWidget_Previews: PreviewProvider {
    static var previews: some View {
        SigoWidgetEntryView(
            entry: SimpleEntry(
                date: Date(),
                title: NSLocalizedString("widget_title", comment: "Widget title"),
                acknowledged: 5,
                held: 2,
                inProgress: 8,
                pending: 3,
                total: 18,
                lastUpdate: Date()
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
