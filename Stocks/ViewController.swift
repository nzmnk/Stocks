//
//  ViewController.swift
//  Stocks
//
//  Created by Никита Зименко on 04.09.2021.
//

import UIKit

final class ViewController: UIViewController {
    
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var imageView: UIImageView!
    
    private let reachabilityService = ReachabilityService()
    
    private let companiesFixed: [String: String] = ["Apple": "AAPL", "Microsoft": "MSFT", "Google": "GOOG", "Amazon": "AMZN", "Facebook": "FB"]
    
    var companiesDict: [String:String] = [:]
    var companiesArr: [String] = []
    
    @IBAction func showHelpAction(_ sender: UIButton) {  // Вызов "Справки" с кнопки
        let title = "How to use Stocks?"
        let message = "Choose from the stock list below to get the most relevant info."
        let helpAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        helpAlert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        self.present(helpAlert, animated: true, completion: nil)
    }
    
    // MARK: - Обработка обычной ошибки
    
    func showErrorAlert() {  // Функция для обработки ошибок
        let title = "An Error Occurred"
        let message = "Try again later"
        let errorAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
    
        self.present(errorAlert, animated: true, completion: nil)
    }
    
    // MARK: - Обработка сетевой ошибки
    
    func showNetworkErrorAlert() {  // Функция для обработки ошибок сети
        let title = "No internet connection"
        let message = "Check network settings and try again later"
        let networkErrorAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        networkErrorAlert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
    
        self.present(networkErrorAlert, animated: true, completion: nil)
    }
    
    // MARK: - Запрос списка компаний
    
    private func requestSymbolList() {
        
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/market/list/gainers?&token=pk_1bcb2ecf9a8b4d58b36f6e7f375b5669") else {
            showErrorAlert() // Обработка ошибки
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else {
                return
            }
            guard // В случае ошибки вывод сообщения в консоль
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
            else {
                print("!!! Network Error")
                return
            }

            self.parseSymbolList(data: data)
        }
        
        if reachabilityService.isConnected {
            dataTask.resume()
        } else {
            showNetworkErrorAlert()
            companiesArr = Array(companiesFixed.keys)
            companiesDict = companiesFixed
            companyPickerView.reloadAllComponents()
            return
        }
    }
    
    // MARK: - Парсинг списка компаний
    
    private func parseSymbolList(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard let json = jsonObject as? Array<Dictionary<String, Any>> else {
                print("!!! Invalid JSON")
                return
            }
            
            companiesArr.removeAll()
            
            json.forEach { node in
                guard let symbol = node["symbol"] as? String,
                      let companyName = node["companyName"] as? String
                      else {
                    return
                }
                self.companiesDict.updateValue(symbol, forKey: companyName)
                self.companiesArr.append(companyName)
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self,
                      let symbol = self.companiesDict.first?.value
                else {
                    return
                }
                self.companyPickerView.reloadAllComponents()
                self.requestQuote(for: symbol)
            }
        } catch {
            print("!!! Error fetching JSON" + error.localizedDescription)
        }
    }
    
    // MARK: - Реализация метода отправки запроса на сервер
    
    private func requestQuote(for symbol: String) {
        
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?&token=pk_1bcb2ecf9a8b4d58b36f6e7f375b5669") else {
            showErrorAlert() // Обработка ошибки
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else {
                return
            }
            guard // В случае ошибки вывод сообщения в консоль
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
            else {
                print("!!! Network Error")
                return
            }

            self.parseQuote(data: data)
        }
        
        if reachabilityService.isConnected {
            dataTask.resume()
        } else {
            showNetworkErrorAlert()
            return
        }
    }
    
    // MARK: - Запрос картинки
    
    private func requestImage(for symbol: String) {
        
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?&token=pk_1bcb2ecf9a8b4d58b36f6e7f375b5669") else {
                showErrorAlert() // Обработка ошибки
                return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else {
                return
            }
            guard // В случае ошибки вывод сообщения в консоль
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
            else {
                print("!!! Network Error")
                return
            }

            self.parseImage(data: data)
        }
        
        if reachabilityService.isConnected {
            imageView.image = UIImage(named: "Placeholder")
            dataTask.resume()
        } else {
            showNetworkErrorAlert()
            return
        }
    }
    
    // MARK: - Парсинг картинки
    
    private func parseImage(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let imageUrl = json["url"] as? String
            else {
                print("!!! Invalid JSON")
                return
            }
            
            guard let url = URL(string: imageUrl) else {
                return
            }
            
            downloadImage(from: url)
            
        } catch {
            print("!!! Error fetching JSON" + error.localizedDescription)
        }
    }
    
    // MARK: - Реализация метода парсинга: получаем JSON
    
    private func parseQuote(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double
            else {
                print("!!! Invalid JSON")
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.displayStockInfo(companyName: companyName,
                                      symbol: companySymbol,
                                      price: price,
                                      priceChange: priceChange)
            }
        } catch {
            print("!!! Error fetching JSON" + error.localizedDescription)
        }
    }
    
    // MARK: - Вывод информации об акции на экран
    
    private func displayStockInfo(companyName: String, symbol: String, price: Double, priceChange: Double) {
        
        activityIndicator.stopAnimating()
        companyNameLabel.text = companyName
        companySymbolLabel.text = symbol
        priceLabel.text = "\(price)"
        priceChangeLabel.text = "\(priceChange)"
        
        if priceChange == .zero {
            priceChangeLabel.textColor = UIColor.black
        } else {
            priceChangeLabel.textColor = priceChange > .zero ? UIColor.green : UIColor.red
        }
    }
    
    // MARK: - Обновление информации по акции при старте приложения
    
    private func requestQuoteUpdate(symbol: String) {
        
        activityIndicator.startAnimating()
        companyNameLabel.text = "—" //При обновлении информации текст будет заменяться прочерком
        companySymbolLabel.text = "—"
        priceLabel.text = "—"
        priceChangeLabel.text = "—"
        priceChangeLabel.textColor = UIColor.black
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedCompany = companiesArr[selectedRow]
        guard let selectedSymbol = companiesDict[selectedCompany] else {
            return
        }
        requestQuote(for: selectedSymbol)
        requestImage(for: selectedSymbol)
    }
    
    // MARK: - viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        
        imageView.image = UIImage(named: "Placeholder")
        requestSymbolList()
    }
}

// MARK: - UIPickerViewDataSource

extension ViewController: UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companiesArr.count
    }
}

// MARK: - UIPickerViewDelegate

extension ViewController: UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return companiesArr[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let companyName = companiesArr[row]
        guard let symbol = companiesDict[companyName] else {
            return
        }
        requestQuoteUpdate(symbol: symbol)
    }
}

// MARK: - UIImage

private extension ViewController {
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

    func downloadImage(from url: URL) {
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else {
                return
            }

            DispatchQueue.main.async() { [weak self] in
                self?.imageView.image = UIImage(data: data)
            }
        }
    }
}
