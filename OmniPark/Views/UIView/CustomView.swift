//
//  CustomView.swift
//  OminPark
//
//  Created by Emanuel  Guerrero on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import UIKit

class CustomView: UIView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 4
        layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 1
        layer.shadowRadius = 0
        layer.masksToBounds = false
    }
}
