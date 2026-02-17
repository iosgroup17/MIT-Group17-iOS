import SwiftUI
import Charts

struct DailyMetric: Identifiable {
    let id = UUID()
    let day: String
    let engagement: Int
    let platform: String // "instagram", "twitter", "linkedin"
}

struct EngagementChartView: View {
    var metrics: [DailyMetric]
    
    // 1. FIXED: Use KeyValuePairs for Chart Colors (Fixes the Error)
    let platformColors: KeyValuePairs<String, Color> = [
        "instagram": .pink,
        "twitter": .black,
        "linkedin": .blue
    ]
    
    // 2. Legend Helper: Unique Platforms Only (Sorted)
    var activePlatforms: [String] {
        let all = Set(metrics.map { $0.platform })
        let order = ["instagram": 0, "twitter": 1, "linkedin": 2]
        return Array(all).sorted { (order[$0] ?? 99) < (order[$1] ?? 99) }
    }
    
    // 3. Axis Formatter (100k)
    func axisLabel(_ value: Int) -> String {
        let doubleVal = Double(value)
        if doubleVal >= 1_000_000 {
            return String(format: "%.1fM", doubleVal / 1_000_000).replacingOccurrences(of: ".0", with: "")
        } else if doubleVal >= 1_000 {
            return String(format: "%.0fk", doubleVal / 1_000)
        }
        return "\(value)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // --- CUSTOM LEGEND (Prevents Repetition) ---
            if !metrics.isEmpty {
                HStack(spacing: 16) {
                    ForEach(activePlatforms, id: \.self) { platform in
                        HStack(spacing: 4) {
                            // Manual Color Lookup
                            Circle()
                                .fill(colorForPlatform(platform))
                                .frame(width: 8, height: 8)
                            
                            Text(platform.capitalized)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading, 4)
                .padding(.bottom, 10)
            }
            
            // --- THE CHART ---
            if metrics.isEmpty {
                ContentUnavailableView("No Data Yet", systemImage: "chart.xyaxis.line", description: Text("Connect platforms to see trends."))
                    .frame(height: 200)
            } else {
                Chart(metrics) { item in
                    
                    // A. The Line
                    LineMark(
                        x: .value("Day", item.day),
                        y: .value("Engagement", item.engagement)
                    )
                    .foregroundStyle(by: .value("Platform", item.platform)) // Distinct Lines
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    // B. The Points (Decorations)
                    PointMark(
                        x: .value("Day", item.day),
                        y: .value("Engagement", item.engagement)
                    )
                    .foregroundStyle(by: .value("Platform", item.platform))
                    .symbolSize(30)
                }
                .chartForegroundStyleScale(platformColors) // Apply Fixed Colors
                .chartLegend(.hidden) // 🛑 HIDE DEFAULT LEGEND (Fixes Repetition)
                .chartYScale(domain: .automatic(includesZero: false)) // 🛑 FIX FLAT LINES
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        if let intValue = value.as(Int.self) {
                            AxisValueLabel(axisLabel(intValue)) // Custom "100k" Label
                        }
                    }
                }
                .frame(height: 220)
            }
        }
        .padding(10)
    }
    
    // Helper to extract color from KeyValuePairs safely
    func colorForPlatform(_ platform: String) -> Color {
        return platformColors.first(where: { $0.key == platform })?.value ?? .gray
    }
}
