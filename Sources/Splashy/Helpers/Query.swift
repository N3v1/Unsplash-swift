//
//  File.swift
//  
//
//  Created by Nevio Hirani on 21.07.24.
//

import Foundation

struct PaginationParams {
    let page: Int?
    let perPage: Int?
    let orderBy: String?
}

func compactDefined(_ dict: [String: Any?]) -> [String: Any] {
    var result = [String: Any]()
    for (key, value) in dict {
        if let definedValue = value {
            result[key] = definedValue
        }
    }
    return result
}

func getCollections(collectionIds: [String]?) -> [String: String] {
    if isDefined(collectionIds), let ids = collectionIds {
        return ["collections": ids.joined(separator: ",")]
    } else {
        return [:]
    }
}

func getTopics(topicIds: [String]?) -> [String: String] {
    if isDefined(topicIds), let ids = topicIds {
        return ["topics": ids.joined(separator: ",")]
    } else {
        return [:]
    }
}

func getFeedParams(paginationParams: PaginationParams) -> [String: Any] {
    let params: [String: Any?] = [
        "per_page": paginationParams.perPage,
        "order_by": paginationParams.orderBy,
        "page": paginationParams.page
    ]
    return compactDefined(params)
}
