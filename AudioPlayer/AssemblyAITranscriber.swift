//
//  AssemblyAITranscriber.swift
//  AudioPlayer
//
//  Created by Anthony Smaldore on 12/6/24.
//

import Foundation

class AssemblyAITranscriber {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // Upload audio file to AssemblyAI
    func uploadAudioFile(localFileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let uploadURL = "https://api.assemblyai.com/v2/upload"
        
        var request = URLRequest(url: URL(string: uploadURL)!)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        // Read file data
        guard let fileData = try? Data(contentsOf: localFileURL) else {
            completion(.failure(NSError(domain: "File read error", code: 0, userInfo: nil)))
            return
        }
        
        let task = URLSession.shared.uploadTask(with: request, from: fileData) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let uploadedURL = json["upload_url"] as? String {
                    completion(.success(uploadedURL))
                } else {
                    completion(.failure(NSError(domain: "Invalid JSON response", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    // Request transcription from AssemblyAI
    func requestTranscription(audioFileURL: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "https://api.assemblyai.com/v2/transcript"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "audio_url": audioFileURL,
            "language_detection": true, // Enables ALD
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let transcriptId = json["id"] as? String {
                    // Poll for transcription completion
                    self.pollTranscriptionStatus(transcriptId: transcriptId, completion: completion)
                } else {
                    completion(.failure(NSError(domain: "Invalid JSON response", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    // Poll transcription status
    private func pollTranscriptionStatus(transcriptId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "https://api.assemblyai.com/v2/transcript/\(transcriptId)"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let status = json["status"] as? String {
                    if status == "completed", let text = json["text"] as? String {
                        completion(.success(text))
                    } else if status == "failed" {
                        completion(.failure(NSError(domain: "Transcription failed", code: 0, userInfo: nil)))
                    } else {
                        // If not completed, poll again after a delay
                        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                            self.pollTranscriptionStatus(transcriptId: transcriptId, completion: completion)
                        }
                    }
                } else {
                    completion(.failure(NSError(domain: "Invalid JSON response", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
