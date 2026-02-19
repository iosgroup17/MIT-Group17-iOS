import SwiftUI
import Charts

struct EngagementChartView: View {
    let metrics: [DailyMetric]
    
    private var filteredAndSortedMetrics: [DailyMetric] {
        let range = currentWeekRange
        return metrics
            .filter { range.contains(Calendar.current.startOfDay(for: $0.date)) }
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
        return monday...sunday
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            if filteredAndSortedMetrics.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(Color(UIColor.systemGray4))
                    
                    Text("No original posts this week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                
            } else {
                // 📊 THE NEW HABIT TRACKER BAR CHART
                Chart {
                    ForEach(filteredAndSortedMetrics) { item in
                        let dayStart = Calendar.current.startOfDay(for: item.date)
                        
                        BarMark(
                            x: .value("Day", dayStart),
                            y: .value("Posts", item.engagement) // 'engagement' now stores post count
                        )
                        .foregroundStyle(by: .value("Platform", item.platform.lowercased()))
                        .cornerRadius(4) // Gives the bars a nice rounded look
                    }
                }
                .chartForegroundStyleScale([
                    "instagram": .pink,
                    "twitter": .black,
                    "linkedin": .blue
                ])
                .chartXScale(domain: currentWeekRange)
                .chartYScale(domain: .automatic(includesZero: true))
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let _ = value.as(Date.self) {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                            AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                                .font(.caption2.bold())
                        }
                    }
                }
                .chartYAxis {
                    // Y-Axis now explicitly shows 0, 1, 2, 3... posts
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        if let intValue = value.as(Int.self) {
                            AxisValueLabel("\(intValue)")
                        }
                    }
                }
                .frame(minHeight: 200)
                
                // 🏷️ CUSTOM LEGEND
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
        .background(Color(UIColor.systemBackground))
        .clipped()
    }
}