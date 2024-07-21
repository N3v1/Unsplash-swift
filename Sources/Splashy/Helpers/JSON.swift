//
//  File.swift
//  
//
//  Created by Nevio Hirani on 21.07.24.
//

import Foundation

func isJSON(_ contentType: String) -> Bool {
    let regex = try! NSRegularExpression(pattern: #"application\/[^+]*[+]?(json);?.*"#, options: [])
    let range = NSRange(location: 0, length: contentType.utf16.count)
    return regex.firstMatch(in: contentType, options: [], range: range) != nil
}

func checkIsJsonResponse(_ response: HTTPURLResponse) -> Bool {
    if let contentTypeHeader = response.allHeaderFields["Content-Type"] as? String {
        return isDefined(contentTypeHeader) && isJSON(contentTypeHeader)
    }
    return false
}

func getJsonResponse(_ response: HTTPURLResponse, data: Data) throws -> AnyJson {
    if checkIsJsonResponse(response) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json
        } catch {
            throw DecodingError(message: "unable to parse JSON response.")
        }
    } else {
        throw DecodingError(message: "expected JSON response from server.")
    }
}
