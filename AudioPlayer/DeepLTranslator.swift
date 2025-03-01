//
//  DeepLTranslator.swift
//  AudioPlayer
//
//  Created by Anthony Smaldore on 2/23/25.
//


import Foundation

class DeepLTranslator {
    private let apiKey: String
    private let apiEndpoint = "https://api-free.deepl.com/v2/translate" // Use "api.deepl.com" for Pro version

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func translateText(_ text: String, targetLang: String = "ES", completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: apiEndpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        // Configure the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")

        // Request body parameters
        let parameters = "text=\(text)&target_lang=\(targetLang)"
        request.httpBody = parameters.data(using: .utf8)

        // Perform the network request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }

            // Parse JSON response
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let translations = json["translations"] as? [[String: Any]],
                   let translatedText = translations.first?["text"] as? String {
                    completion(.success(translatedText))
                } else {
                    completion(.failure(NSError(domain: "Unexpected response format", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

