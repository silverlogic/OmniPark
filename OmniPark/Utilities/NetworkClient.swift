//
//  NetworkClient.swift
//  OmniPark
//
//  Created by Emanuel  Guerrero on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import Foundation
import Alamofire

final class NetworkClient {
    
    // MARK: - Public Instance Methods
    func performRequest(url: String,
                        httpMethod: HTTPMethod,
                        parameters: Parameters?,
                        headers: HTTPHeaders?,
                        completion: @escaping (_ response: Data?, _ error: Error?) -> Void) {
        Alamofire.request(url, method: httpMethod,
                          parameters: parameters,
                          encoding: JSONEncoding(),
                          headers: headers)
        .validate()
        .responseData { (response) in
            switch response.result {
            case .success(let value):
                completion(value, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}
