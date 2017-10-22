//
//  Offer.swift
//  OmniPark
//
//  Created by Emanuel  Guerrero on 10/22/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import Foundation

struct Offer: Decodable {
    let offerId: Int16
    let name: String
    let offerDescription: String
    
    
    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case offerId = "id"
        case name = "name"
        case offerDescription = "description"
    }
}

final class OfferManager {
    
    // MARK: - Shared Instance
    static let shared = OfferManager()
    
    
    // MARK: - Private Instance Attributes
    private var offers: [Offer] = []
    
    
    // MARK: - Initializers
    private init() {}
    
    
    // MARK: - Public Instance Methods
    func fetchOffers() {
        let url = "\(BASE_URL)/offers"
        DispatchQueue.global(qos: .userInitiated).async {
            let networkClient = NetworkClient()
            networkClient.performRequest(url: url, httpMethod: .get, parameters: nil, headers: nil) { (data, error) in
                guard error == nil else {
                    print("Error retrieving offers")
                    print(error!)
                    return
                }
                guard let responseData = data else {
                    print("No response data for offers")
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let offers = try decoder.decode([Offer].self, from: responseData)
                    self.offers = offers
                    print("Offers retrieved")
                } catch {
                    print("Error parsing response data for offers")
                    print(error)
                }
            }
        }
    }
}
