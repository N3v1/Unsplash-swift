//
//  File.swift
//  
//
//  Created by Nevio Hirani on 21.07.24.
//

import Foundation

struct ApiResponse<T: Decodable>: Decodable {
    let data: T
}

typealias S_HandleResponse<T: Decodable> = (Data, URLResponse) throws -> T
typealias BuildUrlParams = (pathname: String, query: [String: String?])

struct FetchParams {
    let method: String
    let headers: [String: String]?
}

struct BaseRequestParams {
    let buildUrlParams: BuildUrlParams
    let fetchParams: FetchParams
    let headers: [String: String]?
}

struct AdditionalFetchOptions {
    let headers: [String: String]?
    let body: Data?
    let signal: Any?
}

struct CompleteRequestParams {
    let buildUrlParams: BuildUrlParams
    let fetchParams: FetchParams
    let headers: [String: String]
    let body: Data?
    let signal: Any?
}

typealias HandleRequest<Args> = (Args, AdditionalFetchOptions?) -> CompleteRequestParams

func createRequestHandler<Args>(
    fn: @escaping (Args) -> BaseRequestParams
) -> HandleRequest<Args> {
    return { args, additionalFetchOptions in
        let baseReqParams = fn(args)
        var headers = baseReqParams.headers ?? [:]

        if let additionalHeaders = additionalFetchOptions?.headers {
            for (key, value) in additionalHeaders {
                headers[key] = value
            }
        }

        return CompleteRequestParams(
            buildUrlParams: baseReqParams.buildUrlParams,
            fetchParams: baseReqParams.fetchParams,
            headers: headers,
            body: additionalFetchOptions?.body,
            signal: additionalFetchOptions?.signal
        )
    }
}

struct InitParams {
    let apiVersion: String?
    let fetch: ((URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask)?
    let accessKey: String?
    let apiUrl: String
    let headers: [String: String]?
}

struct RequestGenerator<Args, ResponseType: Decodable> {
    let handleRequest: HandleRequest<Args>
    let handleResponse: S_HandleResponse<ResponseType>
}

struct Endpoint<PathnameParams, RequestArgs, ResponseType: Decodable> {
    let getPathname: (PathnameParams) -> String
    let handleRequest: HandleRequest<RequestArgs>
    let handleResponse: S_HandleResponse<ResponseType>
}

func makeEndpoint<PathnameParams, RequestArgs, ResponseType: Decodable>(
    endpoint: Endpoint<PathnameParams, RequestArgs, ResponseType>
) -> Endpoint<PathnameParams, RequestArgs, ResponseType> {
    return endpoint
}

//typealias AnyRequestGenerator = (Any, AdditionalFetchOptions?) -> AnyCompleteRequestParams
//typealias AnyPromise = Promise<ApiResponse<Any>>

//typealias InitMakeRequest = <Args, ResponseType: Decodable>(
//    InitParams
//) -> (RequestGenerator<Args, ResponseType>) -> (Args, AdditionalFetchOptions?) -> Promise<ApiResponse<ResponseType>>

typealias InitMakeRequest = (
    InitParams
) -> (AnyRequestGenerator) -> (Any, AdditionalFetchOptions?) -> AnyPromise


func buildUrl(params: BuildUrlParams, baseUrl: String) -> String {
    var components = URLComponents(string: baseUrl)!
    components.path += params.pathname
    components.queryItems = params.query.compactMap { key, value in
        guard let value = value else { return nil }
        return URLQueryItem(name: key, value: value)
    }
    return components.url!.absoluteString
}

func initMakeRequest<Args, ResponseType: Decodable>(
    initParams: InitParams
) -> (RequestGenerator<Args, ResponseType>) -> (Args, AdditionalFetchOptions?) -> Promise<ApiResponse<ResponseType>> {
    return { handlers in
        return { args, additionalFetchOptions in
            let completeRequestParams = handlers.handleRequest(args, additionalFetchOptions)
            let url = buildUrl(params: completeRequestParams.buildUrlParams, baseUrl: initParams.apiUrl)
            
            var request = URLRequest(url: URL(string: url)!)
            request.httpMethod = completeRequestParams.fetchParams.method
            request.allHTTPHeaderFields = completeRequestParams.headers
            request.httpBody = completeRequestParams.body

            return Promise<ApiResponse<ResponseType>> { resolve, reject in
                let fetchToUse: (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
                
                if let customFetch = initParams.fetch {
                    fetchToUse = customFetch
                } else {
                    fetchToUse = { req, completion in
                        return URLSession.shared.dataTask(with: req, completionHandler: completion)
                    }
                }

                let task = fetchToUse(request) { data, response, error in
                    if let error = error {
                        reject(error)
                        return
                    }
                    guard let data = data, let response = response else {
                        reject(DecodingError(message: "Invalid response"))
                        return
                    }
                    do {
                        let parsedResponse = try handlers.handleResponse(data, response)
                        resolve(ApiResponse(data: parsedResponse))
                    } catch {
                        reject(error)
                    }
                }
                
                task.resume()
            }
        }
    }
}

class Promise<T> {
    typealias Completion = (T) -> Void
    typealias ErrorCompletion = (Error) -> Void
    
    private var successCompletion: Completion?
    private var errorCompletion: ErrorCompletion?
    
    init(_ executor: (@escaping Completion, @escaping ErrorCompletion) -> Void) {
        executor(self.resolve, self.reject)
    }
    
    func then(_ completion: @escaping Completion) -> Promise {
        self.successCompletion = completion
        return self
    }
    
    func `catch`(_ completion: @escaping ErrorCompletion) -> Promise {
        self.errorCompletion = completion
        return self
    }
    
    private func resolve(_ value: T) {
        successCompletion?(value)
    }
    
    private func reject(_ error: Error) {
        errorCompletion?(error)
    }
}
