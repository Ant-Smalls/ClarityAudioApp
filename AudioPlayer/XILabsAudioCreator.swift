//
//  XILabsAudioCreator.swift
//  AudioPlayer
//
//  Created by Anthony Smaldore on 12/6/24.
//


import Foundation

class ElevenLabsAPI {
    private let apiKey: String
    private let apiEndpoint = "https://api.elevenlabs.io/v1/text-to-speech/LuJj551LhJ7vMONG4u8r" // Adjust as per Eleven Labs documentation
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // Generate audio from text using Eleven Labs API
    func generateSpeech(from text: String, completion: @escaping (Result<URL, Error>) -> Void) {
        // Create the Eleven Labs request URL (replace `voice_id` with your specific voice ID)
        //let voiceId = "LuJj551LhJ7vMONG4u8r" // Replace with actual Eleven Labs voice ID
        guard let url = URL(string: "\(apiEndpoint)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        // Configure the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.addValue("\(apiKey)", forHTTPHeaderField: "xi-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Request body with the text to synthesize
        let requestBody: [String: Any] = ["text": text, "voice_settings": ["stability": 0.5, "similarity_boost": 0.5]]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        // Perform the network request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Debug: Log response headers and status code
            if let httpResponse = response as? HTTPURLResponse {
                print("Http status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            // Save the audio file locally
            do {
                let outputDirectory = self.getElevenLabsAudioDirectory()
                let fileName = UUID().uuidString + ".mp3"
                let outputURL = outputDirectory.appendingPathComponent(fileName)
                try data.write(to: outputURL)
                completion(.success(outputURL))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    // Helper function to get or create the Eleven Labs audio directory
    private func getElevenLabsAudioDirectory() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let elevenLabsDirectory = documentsDirectory.appendingPathComponent("ElevenLabsAudio")
        print(elevenLabsDirectory)
        if !FileManager.default.fileExists(atPath: elevenLabsDirectory.path) {
            try? FileManager.default.createDirectory(at: elevenLabsDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return elevenLabsDirectory
    }
}

