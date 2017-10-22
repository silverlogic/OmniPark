//
//  SCNMaterial+Extension.swift
//  OmniPark
//
//  Created by Vasilii Muravev on 10/22/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import SceneKit

extension SCNMaterial {
    
    // MARK: - Initializers
    convenience init(color: UIColor) {
        self.init()
        diffuse.contents = color
    }
    
    convenience init(image: UIImage) {
        self.init()
        diffuse.contents = image
    }
}
