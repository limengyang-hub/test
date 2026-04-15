//
//  CalculatorView.swift
//  test01
//

import SwiftUI

// MARK: - 四则运算核心

private enum BinaryOp: Hashable {
    case add, sub, mul, div

    func apply(_ a: Double, _ b: Double) -> Double? {
        switch self {
        case .add: return a + b
        case .sub: return a - b
        case .mul: return a * b
        case .div: return b == 0 ? nil : a / b
        }
    }
}

private enum Pending {
    case none
    case awaitingRhs(op: BinaryOp, lhs: Double)
}

/// 简单四则运算（从左到右连续运算，按一次运算符会合并上一段）
private struct ArithmeticBrain {
    var screen: String = "0"
    var pending: Pending = .none
    var newEntry: Bool = true

    private static func format(_ v: Double) -> String {
        if v.isNaN || v.isInfinite { return "错误" }
        if abs(v.rounded() - v) < 1e-9, abs(v) < 1e15 {
            return String(format: "%.0f", v)
        }
        var s = String(format: "%.10g", v)
        if s.hasSuffix(".0") { s.removeLast(2) }
        return s
    }

    mutating func digit(_ d: Character) {
        guard d.isNumber || d == "." else { return }
        if newEntry {
            if d == "." {
                screen = "0."
            } else {
                screen = String(d)
            }
            newEntry = false
            return
        }
        if d == "." {
            if !screen.contains(".") { screen.append(".") }
            return
        }
        if screen == "0" {
            screen = String(d)
        } else {
            screen.append(d)
        }
    }

    mutating func deleteLast() {
        guard !newEntry else { return }
        if screen.count <= 1 {
            screen = "0"
            newEntry = true
        } else {
            screen.removeLast()
        }
    }

    mutating func binaryOp(_ o: BinaryOp) {
        let x = Double(screen)
        guard let cur = x, !cur.isNaN else { return }

        switch pending {
        case .none:
            pending = .awaitingRhs(op: o, lhs: cur)
        case .awaitingRhs(let op0, let lhs):
            if newEntry {
                pending = .awaitingRhs(op: o, lhs: lhs)
                return
            }
            guard let r = op0.apply(lhs, cur) else {
                screen = "错误"
                pending = .none
                newEntry = true
                return
            }
            screen = Self.format(r)
            pending = .awaitingRhs(op: o, lhs: r)
        }
        newEntry = true
    }

    mutating func equals() {
        guard case .awaitingRhs(let op0, let lhs) = pending else { return }
        let rhs = Double(screen) ?? 0
        guard let r = op0.apply(lhs, rhs) else {
            screen = "错误"
            pending = .none
            newEntry = true
            return
        }
        screen = Self.format(r)
        pending = .none
        newEntry = true
    }

    mutating func clearAll() {
        screen = "0"
        pending = .none
        newEntry = true
    }

    mutating func negate() {
        guard screen != "错误", let v = Double(screen) else { return }
        screen = Self.format(-v)
    }
}

// MARK: - 进制换算

private enum RadixHelper {
    static let commonBases = [2, 8, 10, 16]

    static func convert(input: String, from: Int, to: Int) -> String {
        let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return "请输入数字" }
        guard (2...36).contains(from), (2...36).contains(to) else { return "进制范围 2…36" }
        guard let v = Int(t, radix: from) else { return "当前进制下无法解析" }
        if to == 10 { return String(v) }
        return String(v, radix: to, uppercase: true)
    }
}

// MARK: - 界面

private enum CalculatorPanel: String, CaseIterable {
    case arithmetic = "四则运算"
    case radix = "进制"
}

struct CalculatorView: View {
    @State private var panel: CalculatorPanel = .arithmetic
    @State private var arith = ArithmeticBrain()

    @State private var radixInput: String = "FF"
    @State private var fromBase: Int = 16
    @State private var toBase: Int = 10
    @State private var radixResult: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Picker("模式", selection: $panel) {
                ForEach(CalculatorPanel.allCases, id: \.self) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            switch panel {
            case .arithmetic:
                arithmeticBody
            case .radix:
                radixBody
            }
        }
        .navigationTitle("计算器")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if radixResult.isEmpty {
                radixResult = RadixHelper.convert(input: radixInput, from: fromBase, to: toBase)
            }
        }
    }

    private var arithmeticBody: some View {
        VStack(spacing: 16) {
            Text(arith.screen)
                .font(.system(size: 36, weight: .medium, design: .monospaced))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

            LazyVGrid(columns: columns, spacing: 10) {
                calcKey("C") { arith.clearAll() }
                calcKey("⌫") { arith.deleteLast() }
                calcKey("±") { arith.negate() }
                opKey("÷") { arith.binaryOp(.div) }

                numKey("7") { arith.digit("7") }
                numKey("8") { arith.digit("8") }
                numKey("9") { arith.digit("9") }
                opKey("×") { arith.binaryOp(.mul) }

                numKey("4") { arith.digit("4") }
                numKey("5") { arith.digit("5") }
                numKey("6") { arith.digit("6") }
                opKey("−") { arith.binaryOp(.sub) }

                numKey("1") { arith.digit("1") }
                numKey("2") { arith.digit("2") }
                numKey("3") { arith.digit("3") }
                opKey("+") { arith.binaryOp(.add) }

                numKey("0") { arith.digit("0") }
                    .gridCellColumns(2)
                numKey(".") { arith.digit(".") }
                calcKey("=") { arith.equals() }
                    .tint(.orange)
            }
            .padding(.horizontal)

            Text("连续运算：输入数字后选运算符，再输入下一数字；可按「=」得到结果。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer(minLength: 0)
        }
    }

    private func numKey(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title2.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.bordered)
    }

    private func opKey(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(.systemOrange))
    }

    private func calcKey(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.bordered)
    }

    private var radixBody: some View {
        Form {
            Section {
                TextField("输入数字（符合「源进制」的字符）", text: $radixInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .onChange(of: radixInput) { _, _ in
                        radixResult = RadixHelper.convert(input: radixInput, from: fromBase, to: toBase)
                    }
            } header: {
                Text("待转换")
            } footer: {
                Text("十六进制可使用 0–9、A–F；八进制为 0–7；二进制为 0–1。")
            }

            Section("源进制") {
                Picker("源", selection: $fromBase) {
                    ForEach(RadixHelper.commonBases, id: \.self) { b in
                        Text(baseLabel(b)).tag(b)
                    }
                }
                .onChange(of: fromBase) { _, _ in
                    radixResult = RadixHelper.convert(input: radixInput, from: fromBase, to: toBase)
                }
            }

            Section("目标进制") {
                Picker("目标", selection: $toBase) {
                    ForEach(RadixHelper.commonBases, id: \.self) { b in
                        Text(baseLabel(b)).tag(b)
                    }
                }
                .onChange(of: toBase) { _, _ in
                    radixResult = RadixHelper.convert(input: radixInput, from: fromBase, to: toBase)
                }
            }

            Section("结果") {
                Text(radixResult)
                    .font(.title3.monospaced())
                    .textSelection(.enabled)
            }
        }
    }

    private func baseLabel(_ b: Int) -> String {
        switch b {
        case 2: return "二进制 (2)"
        case 8: return "八进制 (8)"
        case 10: return "十进制 (10)"
        case 16: return "十六进制 (16)"
        default: return "\(b) 进制"
        }
    }
}

#Preview("计算器") {
    NavigationStack {
        CalculatorView()
    }
}
