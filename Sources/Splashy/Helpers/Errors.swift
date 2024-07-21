//
//  File.swift
//  
//
//  Created by Nevio Hirani on 21.07.24.
//

import Foundation

public typealias AnyJson = Any
public typealias JsonMap = [String: Any]
public typealias NonEmptyArray = [String]
public typealias Nullable<T> = T?

enum ErrorSource {
    case api
    case decoding
}

func isDefined(_ value: Any?) -> Bool {
    return value != nil
}

func checkIsString(_ value: Any) -> Bool {
    return value is String
}

func checkIsNonEmptyArray(_ array: [Any]) -> Bool {
    return !array.isEmpty
}

func getRefinement<T>(_ refinement: @escaping (AnyJson) -> Nullable<T>) -> (AnyJson) -> Nullable<T> {
    return refinement
}

let checkIsObject = getRefinement { (response: AnyJson) -> Nullable<JsonMap> in
    if isDefined(response), let dict = response as? JsonMap {
        return dict
    } else {
        return nil
    }
}

let checkIsErrors = getRefinement { (errors: AnyJson) -> Nullable<NonEmptyArray> in
    if let array = errors as? [Any], array.allSatisfy(checkIsString), checkIsNonEmptyArray(array) {
        return array as? NonEmptyArray
    } else {
        return nil
    }
}

let checkIsApiError = getRefinement { (response: AnyJson) -> Nullable<[String: NonEmptyArray]> in
    if let obj = checkIsObject(response), let errors = obj["errors"], let errorsArray = checkIsErrors(errors) {
        return ["errors": errorsArray]
    } else {
        return nil
    }
}

func getErrorForBadStatusCode(jsonResponse: AnyJson) -> (errors: NonEmptyArray, source: ErrorSource) {
    if let apiError = checkIsApiError(jsonResponse) {
        return (errors: apiError["errors"]!, source: .api)
    } else {
        return (errors: ["Responded with a status code outside the 2xx range, and the response body is not recognisable."], source: .decoding)
    }
}

class DecodingError: Error {
    let message: String
    
    init(message: String) {
        self.message = message
    }
}
