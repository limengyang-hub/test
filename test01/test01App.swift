//
//  test01App.swift
//  test01
//
//  Created by 1111 on 2026/4/14.
//

import Combine
import SwiftUI

// 货币转化器（经 App 注入，ContentView 用 @EnvironmentObject 读取）
@MainActor
class CurrencyConverter: ObservableObject {
    /// 各币种相对 1 USD 的「数量」（演示用固定汇率，非实时牌价）
    static let unitsPerUSD: [String: Double] = [
        "USD": 1.0,
        "CNY": 7.24,
        "EUR": 0.92,
        "GBP": 0.79,
        "JPY": 151.0,
        "HKD": 7.82,
        "KRW": 1_380.0
    ]

    static var supportedCodes: [String] {
        Self.unitsPerUSD.keys.sorted()
    }

    @Published var amount: Double = 100
    @Published var fromCurrency: String = "USD"
    @Published var toCurrency: String = "CNY"
    @Published private(set) var convertedAmount: Double = 0

    init() {
        recalculate()
    }

    func recalculate() {
        let from = Self.unitsPerUSD[fromCurrency] ?? 1
        let to = Self.unitsPerUSD[toCurrency] ?? 1
        guard from > 0 else {
            convertedAmount = 0
            return
        }
        // 先换成美元再换成目标币：amount / fromUnits * toUnits
        convertedAmount = (amount / from) * to
    }

    func swapCurrencies() {
        let a = fromCurrency
        fromCurrency = toCurrency
        toCurrency = a
        recalculate()
    }
}

@main
struct test01App: App {
    @StateObject private var converter = CurrencyConverter()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(converter)
        }
    }
}
