//
//  ParkBooking.swift
//  OmniPark
//
//  Created by Emanuel  Guerrero on 10/22/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import Foundation

enum BookingError: Error {
    case notAuthenticated
    case parse
}

final class ParkBooking: Decodable {
    let parkBookingId: Int16
    let parkingSpotId: Int16
    let startDate: Date
    let endDate: Date
    
    enum CodingKeys: String, CodingKey {
        case parkBookingId = "id"
        case parkingSpotId = "spot"
        case startDate = "start"
        case endDate = "end"
    }
    
    init(from decoder: Decoder) throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let values = try decoder.container(keyedBy: CodingKeys.self)
        parkBookingId = try values.decode(Int16.self, forKey: .parkBookingId)
        parkingSpotId = try values.decode(Int16.self, forKey: .parkingSpotId)
        let start = try values.decode(String.self, forKey: .startDate)
        startDate = dateFormatter.date(from: start)!
        let end = try values.decode(String.self, forKey: .endDate)
        endDate = dateFormatter.date(from: end)!
    }
}

final class ParkBookingManager {
    
    // MARK: - Shared Instance
    static let shared = ParkBookingManager()
    
    
    // MARK: - Private Instance Attributes
    var parkBooking: ParkBooking?
    
    
    // MARK: - Initializers
    private init() {}
    
    
    // MARK: - Public Instance Methods
    func bookParkingSpot(_ parkingSpotId: Int16, startDate: Date, endDate: Date, completion: @escaping (_ error: Error?) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let formatedStartDate = dateFormatter.string(from: startDate)
        let formatedEndDate = dateFormatter.string(from: endDate)
        guard let token = UserManager.shared.token else {
            completion(BookingError.notAuthenticated)
            return
        }
        let url = "\(BASE_URL)/bookings"
        let headers: [String: String] = ["Authorization": "Token \(token)"]
        let body: [String: Any] = ["spot": parkingSpotId, "start": formatedStartDate, "end": formatedEndDate]
        DispatchQueue.global(qos: .userInitiated).async {
            let networkClient = NetworkClient()
            networkClient.performRequest(url: url, httpMethod: .post, parameters: body, headers: headers) { (data, error) in
                DispatchQueue.main.async {
                    guard error == nil else {
                        print("Error booking parking spot")
                        print(error!)
                        completion(error!)
                        return
                    }
                    guard let responseData = data else {
                        print("No response data for park booking")
                        completion(BookingError.parse)
                        return
                    }
                    do {
                        let decoder = JSONDecoder()
                        let parkBooking = try decoder.decode(ParkBooking.self, from: responseData)
                        self.parkBooking = parkBooking
                        completion(nil)
                    } catch {
                        print("Error parsing response data for parking booking")
                        print(error)
                        completion(error)
                    }
                }
            }
        }
    }
    
    func extendParkBooking(completion: @escaping (_ error: Error?) -> Void) {
        
    }
}
