//
//  File.swift
//  
//
//  Created by Nevio Hirani on 21.07.24.
//

import Foundation

typealias HandleResponse<T> = (Response) -> T

let TOTAL_RESPONSE_HEADER = "x-total"

func getTotalFromApiFeedResponse(_ response: HTTPURLResponse) throws -> Int {
    if let totalsStr = response.allHeaderFields[TOTAL_RESPONSE_HEADER] as? String,
       isDefined(totalsStr) {
        if let total = Int(totalsStr), total >= 0 {
            return total
        } else {
            throw DecodingError(message: "expected \(TOTAL_RESPONSE_HEADER) header to be valid integer.")
        }
    } else {
        throw DecodingError(message: "expected \(TOTAL_RESPONSE_HEADER) header to exist.")
    }
}

struct FeedResponse<T> {
    let results: [T]
    let total: Int
}

func handleFeedResponse<T: Decodable>() -> HandleResponse<FeedResponse<T>> {
    return { response in
        guard let httpResponse = response.httpResponse else {
            fatalError("Invalid response type")
        }
        
        let data = response.data
        do {
            let results = try JSONDecoder().decode([T].self, from: data)
            let total = try getTotalFromApiFeedResponse(httpResponse)
            return FeedResponse(results: results, total: total)
        } catch {
            fatalError("Decoding error: \(error)")
        }
    }
}

struct Response {
    let data: Data
    let urlResponse: URLResponse
}

extension Response {
    var httpResponse: HTTPURLResponse? {
        return urlResponse as? HTTPURLResponse
    }
}

func castResponse<T: Decodable>(data: Data) throws -> T {
    return try JSONDecoder().decode(T.self, from: data)
}
