//
//  TodayViewController.swift
//  ForexWidget
//
//  Created by Ilgar Ilyasov on 12/3/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import NotificationCenter
import ForexCore

class TodayViewController: UIViewController, NCWidgetProviding {
    
    // MARK: - Properties
        
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var rateHistoryView: RateHistoryView!
    
    private let fetcher = ExchangeRateFetcher()
    private var symbol: String {
        return groupUserDefaults?.string(forKey: "LastViewedSymbol") ?? "EUR"
    }
    
    private let currencyFormatter: NumberFormatter = {
        let result = NumberFormatter()
        
        result.numberStyle = .decimal
        result.maximumFractionDigits = 2
        result.minimumIntegerDigits = 1
        
        return result
    }()
    
    let groupUserDefaults = UserDefaults(suiteName: "group.com.lambdaschool.ForexIlqar")

    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    }
    
    // MARK: - NCWidgetProviding
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        switch activeDisplayMode {
        case .compact:
            preferredContentSize = maxSize
            self.rateHistoryView.isHidden = true
        case .expanded:
            preferredContentSize = CGSize(width: maxSize.width, height: 200.0)
            rateHistoryView.isHidden = false
        }
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        
        fetcher.fetchCurrentExchangeRate(for: symbol) { (rate, error) in
            if let error = error {
                NSLog("Error fetching current exchange rate: \(error)")
                completionHandler(NCUpdateResult.failed)
                return
            }
            
            guard let rate = rate else {
                completionHandler(.noData)
                return
            }
            
            DispatchQueue.main.async {
                let rateString = self.currencyFormatter.string(from: rate.rate as NSNumber) ?? "N/A"
                self.currencyLabel.text = "\(rateString) \(rate.symbol) = 1 \(rate.base)"
            }
            completionHandler(.newData)
        }
        
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        var components = DateComponents()
        components.calendar = calendar
        components.year = -1
        let aYearAgo = calendar.date(byAdding: components, to: now)!
        
        fetcher.fetchExchangeRates(startDate: aYearAgo, symbols: [symbol]) { (rates, error) in
            if let error = error {
                NSLog("Error fetching historical exchange rate: \(error)")
                return
            }
            
            guard let rates = rates else { return }
            
            DispatchQueue.main.async {
                self.rateHistoryView.exchangeRates = rates
            }
        }
    }
    
}
