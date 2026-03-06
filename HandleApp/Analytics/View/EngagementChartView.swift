import SwiftUI
import Charts

struct EngagementChartView: View {
    let metrics: [DailyMetric]
    let connectedPlatforms: Set<String>
    
    private var filteredAndSortedMetrics: [DailyMetric] {
        let range = currentWeekRange
        return metrics
            .filter {
                range.contains(Calendar.current.startOfDay(for: $0.date)) &&
                connectedPlatforms.contains($0.platform.lowercased())
            }
            .sorted { $0.date < $1.date }
    }
    
    private var activePlatforms: [String] {
        Array(Set(filteredAndSortedMetrics.map { $0.platform.lowercased() })).sorted()
    }
    
    private let platformColors: [String: Color] = [
        "instagram": .pink,
        "twitter": .black,
        "linkedin": .blue
    ]
    
    var currentWeekRange: ClosedRange<Date> {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let now = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        guard let monday = calendar.date(from: components) else { return now...now }
        
        let sunday = calendar.date(byAdding: .day, value: 6, to: monday)!
        let endOfSunday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: sunday)!
        
        return monday...endOfSunday
    }
    
    var currentWeekDays: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let now = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        guard let monday = calendar.date(from: components) else { return [] }
        return (0...6).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            if connectedPlatforms.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(Color(uiColor: .systemGray4))
                    Text("Connect a platform to track your consistency")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                
            } else if filteredAndSortedMetrics.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(Color(uiColor: .systemGray4))
                    Text("No original posts this week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                
            } else {
                Chart {
                    ForEach(filteredAndSortedMetrics) { item in
                        let dayStart = Calendar.current.startOfDay(for: item.date)
                        
                        BarMark(
                            x: .value("Day", dayStart, unit: .day),
                            y: .value("Posts", item.engagement),
                            width: .ratio(0.6)
                        )
                        .foregroundStyle(by: .value("Platform", item.platform.lowercased()))
                        .cornerRadius(4)
                    }
                }
                .chartForegroundStyleScale([
                    "instagram": .pink,
                    "twitter": .black,
                    "linkedin": .blue
                ])
                .chartXScale(domain: currentWeekRange, range: .plotDimension(startPadding: 10, endPadding: 10))
                .chartYScale(domain: .automatic(includesZero: true))
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks(values: currentWeekDays) { value in
                        if let _ = value.as(Date.self) {
                            AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                                .font(.caption2.bold())
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        if let intValue = value.as(Int.self) {
                            AxisValueLabel("\(intValue)")
                        }
                    }
                }
                .frame(minHeight: 200)
                
                HStack(spacing: 16) {
                    ForEach(activePlatforms, id: \.self) { platform in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(platformColors[platform] ?? .gray)
                                .frame(width: 8, height: 8)
                            Text(platform.capitalized)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading, 10)
            }
        }
        .padding(.horizontal, 15)
        .padding(.top, 20)
        .padding(.bottom, 10)
        .background(Color(uiColor: .systemBackground))
        .clipped()
    }
}
