//
//  File.swift
//  
//
//  Created by Nevio Hirani on 21.07.24.
//

import Foundation

func compactDefined<A>(_ dict: [String: A?]) -> [String: A] {
    var result = [String: A]()
    for (key, value) in dict {
        if let definedValue = value {
            result[key] = definedValue
        }
    }
    return result
}

func flow<A, B>(_ ab: @escaping (A) -> B) -> (A) -> B {
    return { a in ab(a) }
}

func flow<A, B, C>(_ ab: @escaping (A) -> B, _ bc: @escaping (B) -> C) -> (A) -> C {
    return { a in bc(ab(a)) }
}

func flow<A, B, C, D>(_ ab: @escaping (A) -> B, _ bc: @escaping (B) -> C, _ cd: @escaping (C) -> D) -> (A) -> D {
    return { a in cd(bc(ab(a))) }
}

func flow(_ fns: [((Any) -> Any)]) -> ((Any) -> Any) {
    return { x in
        var y: Any = fns[0](x)
        for i in 1..<fns.count {
            y = fns[i](y)
        }
        return y
    }
}
