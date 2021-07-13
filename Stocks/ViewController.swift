//
//  ViewController.swift
//  Stocks
//
//  Created by Никита Зименко on 11.07.2021.
//

import UIKit


class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    private let companies: [String: String] = ["Apple": "AAPL", "Microsoft": "MSFT", "Google": "GOOG", "Amazon": "AMZN", "Facebook": "FB"]
    
    
    // Реализация метода UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.companies.keys.count
    }
    
    
    // Реализация метода UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(self.companies.keys)[row]
    }

    
    // Реализация метода отправки запроса на сервер
    private func requestQuote(for symbol: String) {
        let url = URL(string: "https://query1.finance.yahoo.com/v7/finance/quote?symbols=\(symbol)")!
        let dataTask = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard           // В случае ошибки вывод сообщения в консоль
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
            else {
                print("!!! Network Error")
                return
            }
            
            self.parseQuote(data: data)
        }
        
        dataTask.resume()
    }
    
    
    // Реализация метода парсинга: получаем JSON
    private func parseQuote(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let quoteResponse = json["quoteResponse"] as? [String: Any],
                let resultArray = quoteResponse["result"] as? Array<Any>,
                let resultObject = resultArray[0] as? [String:Any],
                let companyName = resultObject["longName"] as? String,
                let companySymbol = resultObject["symbol"] as? String,
                let price = resultObject["regularMarketPrice"] as? Double,
                let priceChange = resultObject["regularMarketChange"] as? Double
            else {
                print("!!! Invalid JSON")
                return
            }
            
            
            DispatchQueue.main.async {
                self.displayStockInfo(companyName: companyName,
                                      symbol: companySymbol,
                                      price: price,
                                      priceChange: priceChange)
            }
        } catch {
            print("!!! Error fetching JSON" + error.localizedDescription)
        }
    }
    
    
    // Реализация метода вывода информации об акции на экран
    private func displayStockInfo(companyName: String, symbol: String, price: Double, priceChange: Double) {
        self.activityIndicator.stopAnimating()
        self.companyNameLabel.text = companyName
        self.companySymbolLabel.text = symbol
        self.priceLabel.text = "\(price)"
        self.priceChangeLabel.text = "\(priceChange)"
    }
    
    
    // Реализация метода pickerView для выбора разных акций
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        self.activityIndicator.startAnimating()
//
//        let selectedSymbol = Array(self.companies.values)[row]
//        self.requestQuote(for: selectedSymbol)
//    }
    
    
    //Реализация метода обновления информации по акции при старте приложения
    private func requestQuoteUpdate() {
        self.activityIndicator.startAnimating()
        self.companyNameLabel.text = "—" //При обновлении информации текст будет заменяться прочерком
        self.companySymbolLabel.text = "—"
        self.priceLabel.text = "—"
        self.priceChangeLabel.text = "—"
        
        let selectedRow = self.companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(self.companies.values)[selectedRow]
        self.requestQuote(for: selectedSymbol)
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.requestQuoteUpdate()
    }
    
    
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.companyPickerView.dataSource = self
        self.companyPickerView.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
        
        self.requestQuoteUpdate()
    }


}

