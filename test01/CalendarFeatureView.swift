//
//  CalendarFeatureView.swift
//  test01
//

import SwiftUI

/// 月历：浏览月份、点选日期、查看当天/选中日在中文环境下的完整描述
struct CalendarFeatureView: View {
    @State private var visibleMonth: Date
    @State private var selectedDate: Date

    private let cal = Calendar.current

    init() {
        let now = Date()
        _visibleMonth = State(initialValue: Self.startOfMonth(for: now))
        _selectedDate = State(initialValue: now)
    }

    var body: some View {
        VStack(spacing: 0) {
            monthHeader

            weekdayHeader

            daysGrid
                .padding(.horizontal, 8)

            Divider()
                .padding(.vertical, 12)

            selectedDetail
                .padding(.horizontal)
                .padding(.bottom)

            Spacer(minLength: 0)
        }
        .navigationTitle("日历")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("今天") {
                    let now = Date()
                    visibleMonth = Self.startOfMonth(for: now)
                    selectedDate = now
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(-1)
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel("上一月")

            Spacer()

            Text(monthYearTitle(visibleMonth))
                .font(.title2.weight(.semibold))

            Spacer()

            Button {
                shiftMonth(1)
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel("下一月")
        }
        .padding()
    }

    private var weekdayHeader: some View {
        let symbols = cal.shortWeekdaySymbols
        let ordered = (0..<7).map { i in
            let idx = (i + cal.firstWeekday - 1) % 7
            return symbols[idx]
        }
        return HStack(spacing: 0) {
            ForEach(Array(ordered.enumerated()), id: \.offset) { _, name in
                Text(name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    private var daysGrid: some View {
        let cells = monthCells(for: visibleMonth)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                switch cell {
                case .empty:
                    Color.clear
                        .frame(minHeight: 40)
                case .day(let date):
                    dayButton(date)
                }
            }
        }
    }

    private func dayButton(_ date: Date) -> some View {
        let dayNum = cal.component(.day, from: date)
        let isToday = cal.isDateInToday(date)
        let isSelected = cal.isDate(date, inSameDayAs: selectedDate)

        return Button {
            selectedDate = date
        } label: {
            Text("\(dayNum)")
                .font(.body.weight(isToday ? .bold : .regular))
                .frame(maxWidth: .infinity, minHeight: 40)
                .background {
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor.opacity(0.35))
                    } else if isToday {
                        Circle()
                            .strokeBorder(Color.accentColor, lineWidth: 2)
                    }
                }
        }
        .buttonStyle(.plain)
        .foregroundStyle(isToday && !isSelected ? Color.accentColor : .primary)
    }

    private var selectedDetail: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选中日期")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(Self.fullDateFormatter.string(from: selectedDate))
                .font(.body)

            if cal.isDateInToday(selectedDate) {
                Label("这一天是今天", systemImage: "sun.max.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func shiftMonth(_ delta: Int) {
        if let d = cal.date(byAdding: .month, value: delta, to: visibleMonth) {
            visibleMonth = Self.startOfMonth(for: d)
        }
    }

    private func monthYearTitle(_ date: Date) -> String {
        Self.monthYearFormatter.string(from: date)
    }

    private enum Cell {
        case empty
        case day(Date)
    }

    private func monthCells(for monthStart: Date) -> [Cell] {
        guard
            let range = cal.range(of: .day, in: .month, for: monthStart),
            let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: monthStart))
        else { return [] }

        let firstWeekday = cal.component(.weekday, from: firstDay)
        let lead = (firstWeekday - cal.firstWeekday + 7) % 7

        var cells: [Cell] = Array(repeating: .empty, count: lead)
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: firstDay) {
                cells.append(.day(d))
            }
        }
        return cells
    }

    private static func startOfMonth(for date: Date) -> Date {
        let c = Calendar.current
        return c.date(from: c.dateComponents([.year, .month], from: date)) ?? date
    }

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.setLocalizedDateFormatFromTemplate("yMMM")
        return f
    }()

    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateStyle = .full
        f.timeStyle = .none
        return f
    }()
}

#Preview("日历") {
    NavigationStack {
        CalendarFeatureView()
    }
}
