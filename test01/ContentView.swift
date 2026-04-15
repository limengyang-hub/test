//
//  ContentView.swift
//  test01
//
//  Created by 1111 on 2026/4/14.
//

import SwiftUI

/// 应用首页：通过按钮进入货币换算
struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)

                Text("工具箱")
                    .font(.title2.weight(.semibold))

                Text("从下面进入货币换算、计算器或日历。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    NavigationLink {
                        CurrencyConverterView()
                    } label: {
                        Label("打开货币换算", systemImage: "dollarsign.circle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    NavigationLink {
                        CalculatorView()
                    } label: {
                        Label("打开计算器", systemImage: "function")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    NavigationLink {
                        CalendarFeatureView()
                    } label: {
                        Label("打开日历", systemImage: "calendar")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 48)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("首页")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// 货币换算功能页（由首页按钮进入）
struct CurrencyConverterView: View {
    @EnvironmentObject private var converter: CurrencyConverter

    private var numberFormat: FloatingPointFormatStyle<Double> {
        .number.precision(.fractionLength(2))
    }

    var body: some View {
        Form {
            Section("金额") {
                TextField("输入数字", value: $converter.amount, format: numberFormat)
                    .keyboardType(.decimalPad)
                    .onChange(of: converter.amount) { _, _ in
                        converter.recalculate()
                    }
            }

            Section("币种") {
                Picker("从", selection: $converter.fromCurrency) {
                    ForEach(CurrencyConverter.supportedCodes, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
                .onChange(of: converter.fromCurrency) { _, _ in
                    converter.recalculate()
                }

                Button {
                    converter.swapCurrencies()
                } label: {
                    Label("交换「从 / 到」", systemImage: "arrow.left.arrow.right")
                }

                Picker("到", selection: $converter.toCurrency) {
                    ForEach(CurrencyConverter.supportedCodes, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
                .onChange(of: converter.toCurrency) { _, _ in
                    converter.recalculate()
                }
            }

            Section("结果") {
                HStack {
                    Text("\(converter.fromCurrency) → \(converter.toCurrency)")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .font(.caption)

                Text(converter.convertedAmount, format: numberFormat)
                    .font(.title2.monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .contentTransition(.numericText())

                Text("汇率为演示数据，与银行实时牌价无关。")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .navigationTitle("货币换算")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("首页") {
    ContentView()
        .environmentObject(CurrencyConverter())
}

#Preview("换算页") {
    NavigationStack {
        CurrencyConverterView()
    }
    .environmentObject(CurrencyConverter())
}
