//
//  User.swift
//  OmniPark
//
//  Created by Emanuel  Guerrero on 10/22/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

struct User {
    let email: String
    let password: String
}

final class UserManager {
    
    // MARK: - Shared Instance
    static let shared = UserManager()
    
    
    // MARK: - Private Instance Attributes
    private let user: User
    var token: String?
    
    
    // MARK: - Initializers
    private init() {
        // Switch which account to use before compiling
        user = User(email: EMAIL_DAVID, password: PASSWORD)
    }
    
    
    // MARK: - Public Instance Methods
    func login() {
        let url = "\(BASE_URL)/login"
        let body = ["email": user.email, "password": user.password]
        DispatchQueue.global(qos: .userInitiated).async {
            let networkClient = NetworkClient()
            networkClient.performRequest(url: url, httpMethod: .post, parameters: body, headers: nil) { (data, error) in
                guard error == nil else {
                    print("Error logining in user")
                    print(error!)
                    return
                }
                guard let responseData = data else {
                    print("No response data for user token")
                    return
                }
                do {
                    let json = try JSON(data: responseData)
                    let token = json["token"].stringValue
                    self.token = token
                    print("Token retrieved")
                } catch {
                    print("Error retrieving JSON for user token")
                    print(error)
                }
            }
        }
    }
}
