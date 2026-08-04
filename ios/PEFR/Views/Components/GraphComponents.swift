import SwiftUI

struct PEFRGraphView: View {
    let records: [PEFRRecord]
    let baseline: Int
    @Binding var isWeekly: Bool
    var showLine: Bool = true
    
    // Config
    private var maxValue: CGFloat { 900 }
    
    private var minValue: CGFloat { 0 }
    
    private var yAxisMarkers: [Int] {
        [0, 100, 200, 300, 400, 500, 600, 700, 800, 900]
    }
    @State private var zoomLevel: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 20) {
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    GeometryReader { geo in
                        let height = geo.size.height
                        let width = geo.size.width * zoomLevel
                        let paddingX: CGFloat = 45
                        let paddingY: CGFloat = 35
                        let chartHeight = height - paddingY * 2
                        let chartWidth = width - paddingX * 2
                        let startX = paddingX
                        let startY = height - paddingY
                        let graphRange = maxValue - minValue
                        
                        Group {
                            // Vertical Grid Lines for Zoom Context
                            if zoomLevel > 1.2 {
                                gridLines(startX: startX, startY: startY, chartWidth: chartWidth, chartHeight: chartHeight)
                            }

                            // X-Axis Top line
                            xAxisTopLine(startX: startX, startY: startY, chartHeight: chartHeight, width: width)
                            
                            // X-Axis Date Labels aligned with data points
                            xAxisLabels(startX: startX, startY: startY, chartWidth: chartWidth, chartHeight: chartHeight)

                            // Y-Axis Markers
                            yAxisMarkersView(startX: startX, startY: startY, chartWidth: chartWidth, chartHeight: chartHeight, width: width, range: graphRange)
                        }

                        if !records.isEmpty {
                            let sortedRecords = records.sorted { (DateUtils.parseRobustDate($0.recordedAt) ?? Date()) < (DateUtils.parseRobustDate($1.recordedAt) ?? Date()) }
                            
                            chartContent(records: sortedRecords, startX: startX, startY: startY, chartWidth: chartWidth, chartHeight: chartHeight, range: graphRange)
                            
                            pointsAndLabels(records: sortedRecords, startX: startX, startY: startY, chartWidth: chartWidth, chartHeight: chartHeight, range: graphRange)
                        }
                    }
                }
                .frame(width: (UIScreen.main.bounds.width - 40) * zoomLevel, height: 260)
            }
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        zoomLevel = min(max(value, 1.0), 3.0)
                    }
            )
            
            // Toggle Pill
            HStack(spacing: 0) {
                ToggleOption(title: "Week", isSelected: isWeekly) { isWeekly = true }
                ToggleOption(title: "Month", isSelected: !isWeekly) { isWeekly = false }
            }
            .background(Color(hex: "#2C5E5E").opacity(0.5))
            .cornerRadius(12)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Sub-views Helper Methods

    @ViewBuilder
    private func gridLines(startX: CGFloat, startY: CGFloat, chartWidth: CGFloat, chartHeight: CGFloat) -> some View {
        ForEach(0..<Int(10 * zoomLevel), id: \.self) { i in
            let x = startX + CGFloat(i) * (chartWidth / CGFloat(max(1, 10 * Int(zoomLevel) - 1)))
            Path { path in
                path.move(to: CGPoint(x: x, y: startY))
                path.addLine(to: CGPoint(x: x, y: startY - chartHeight))
            }
            .stroke(Color.gray.opacity(0.05), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func xAxisTopLine(startX: CGFloat, startY: CGFloat, chartHeight: CGFloat, width: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: startX, y: startY - chartHeight))
            path.addLine(to: CGPoint(x: width - startX, y: startY - chartHeight))
        }
        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    }

    @ViewBuilder
    private func xAxisLabels(startX: CGFloat, startY: CGFloat, chartWidth: CGFloat, chartHeight: CGFloat) -> some View {
        if !records.isEmpty {
            let sorted = records.sorted { (DateUtils.parseRobustDate($0.recordedAt) ?? Date()) < (DateUtils.parseRobustDate($1.recordedAt) ?? Date()) }
            let total = sorted.count
            let maxLabels = isWeekly ? 7 : 5
            let step = max(1, total / maxLabels)
            
            ForEach(0..<total, id: \.self) { index in
                if index % step == 0 || index == total - 1 {
                    let x = startX + (CGFloat(index) / CGFloat(max(1, total - 1))) * chartWidth
                    let record = sorted[index]
                    let dateLabel = getSmartDateLabel(record: record, index: index, sorted: sorted)
                    
                    Text(dateLabel)
                        .font(.system(size: 8))
                        .foregroundColor(.black.opacity(0.5))
                        .frame(width: 40)
                        .position(x: x, y: startY + 15)
                }
            }
        } else {
            let labelCount = isWeekly ? 7 : 5
            ForEach(0..<labelCount, id: \.self) { i in
                let x = startX + CGFloat(i) * (chartWidth / CGFloat(labelCount - 1))
                let dateLabel = getEmptyStateDateLabel(i: i, labelCount: labelCount)
                
                Text(dateLabel)
                    .font(.system(size: 8))
                    .foregroundColor(.black.opacity(0.5))
                    .frame(width: 40)
                    .position(x: x, y: startY + 15)
            }
        }
    }

    private func getSmartDateLabel(record: PEFRRecord, index: Int, sorted: [PEFRRecord]) -> String {
        let currentD = DateUtils.formatDisplayDate(record.recordedAt, format: isWeekly ? "EE" : "d MMM")
        if index > 0 {
            let prevRecord = sorted[index - 1]
            let prevD = DateUtils.formatDisplayDate(prevRecord.recordedAt, format: isWeekly ? "EE" : "d MMM")
            if currentD == prevD {
                return "" // No need of time; don't repeat the date if it's the same day
            }
        }
        return currentD
    }

    private func getEmptyStateDateLabel(i: Int, labelCount: Int) -> String {
        let calendar = Calendar.current
        let offset = isWeekly ? ((labelCount - 1) - i) : ((labelCount - 1) - i) * 7
        let labelDate = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
        let df = DateFormatter()
        df.dateFormat = isWeekly ? "EE" : "d MMM"
        return df.string(from: labelDate)
    }

    @ViewBuilder
    private func yAxisMarkersView(startX: CGFloat, startY: CGFloat, chartWidth: CGFloat, chartHeight: CGFloat, width: CGFloat, range: CGFloat) -> some View {
        ForEach(yAxisMarkers, id: \.self) { marker in
            let y = startY - (CGFloat(marker) - minValue) / range * chartHeight
            
            Text("\(marker)")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.black.opacity(0.7))
                .frame(width: 35, alignment: .trailing)
                .position(x: startX - 25, y: y)
            
            Path { path in
                path.move(to: CGPoint(x: startX, y: y))
                path.addLine(to: CGPoint(x: width - startX, y: y))
            }
            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func chartContent(records: [PEFRRecord], startX: CGFloat, startY: CGFloat, chartWidth: CGFloat, chartHeight: CGFloat, range: CGFloat) -> some View {
        if showLine {
            // Area Fill
            Path { path in
                for (index, record) in records.enumerated() {
                    let x = startX + (CGFloat(index) / CGFloat(max(1, records.count - 1))) * chartWidth
                    let y = startY - (CGFloat(record.pefrValue) - minValue) / range * chartHeight
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: startY))
                        path.addLine(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    if index == records.count - 1 {
                        path.addLine(to: CGPoint(x: x, y: startY))
                        path.closeSubpath()
                    }
                }
            }
            .fill(
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)]), startPoint: .top, endPoint: .bottom)
            )

            // Line
            Path { path in
                for (index, record) in records.enumerated() {
                    let x = startX + (CGFloat(index) / CGFloat(max(1, records.count - 1))) * chartWidth
                    let y = startY - (CGFloat(record.pefrValue) - minValue) / range * chartHeight
                    if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(Color.blue, lineWidth: 2)
        }
    }

    @ViewBuilder
    private func pointsAndLabels(records: [PEFRRecord], startX: CGFloat, startY: CGFloat, chartWidth: CGFloat, chartHeight: CGFloat, range: CGFloat) -> some View {
        ForEach(Array(records.enumerated()), id: \.offset) { index, record in
            let x = startX + (CGFloat(index) / CGFloat(max(1, records.count - 1))) * chartWidth
            let y = startY - (CGFloat(record.pefrValue) - minValue) / range * chartHeight
            
            Text("\(record.pefrValue)")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.blue)
                .position(x: x, y: y - 14)
            
            if showLine {
                Circle()
                    .stroke(Color.blue, lineWidth: 1.5)
                    .background(Circle().fill(Color.white))
                    .frame(width: 8, height: 8)
                    .position(x: x, y: y)
            } else {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
                    .position(x: x, y: y)
            }
        }
    }
}

struct FullScreenGraphView: View {
    let records: [PEFRRecord]
    let baseline: Int
    @Binding var isWeekly: Bool
    @Binding var showFullScreenGraph: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.clear // Transparent to let the blurred background show through
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Interactive Analysis")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text("Pinch to zoom • Drag to move")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Button(action: { 
                        withAnimation { showFullScreenGraph = false }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 40)
                
                Spacer()
                
                // Graph Container
                ZStack {
                    PEFRGraphView(
                        records: records,
                        baseline: baseline,
                        isWeekly: $isWeekly,
                        showLine: true
                    )
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.4), radius: 20)
                    .padding(20)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale *= delta
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                },
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }
                }
                
                Spacer()
                
                // Reset Button
                Button(action: {
                    withAnimation(.spring()) {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset Graph")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(25)
                }
                .padding(.bottom, 60)
            }
        }
    }
}

struct ToggleOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(isSelected ? Color.cardLightBackgroundColor : Color.clear)
                .cornerRadius(10)
                .padding(2)
        }
    }
}
