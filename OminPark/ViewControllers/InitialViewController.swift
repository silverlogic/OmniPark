//
//  InitialViewController.swift
//  OmniPark
//
//  Created by Vasilii Muravev on 10/22/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import UIKit

class InitialViewController: UIViewController {

    @IBOutlet weak var topLevelConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomLevelConstraint: NSLayoutConstraint!
    @IBOutlet weak var textWidth: NSLayoutConstraint!
    @IBOutlet weak var logoWidth: NSLayoutConstraint!
    @IBOutlet weak var logoTop: NSLayoutConstraint!
    @IBOutlet weak var omniLeading: NSLayoutConstraint!
    @IBOutlet weak var parkTrailing: NSLayoutConstraint!
    
    
    var animateCompletion: (() -> Void)? {
        didSet {
            if !animationFinished {
                return
            }
            animateCompletion?()
        }
    }
    var animationFinished: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textWidth.constant = 1.0
        self.logoWidth.constant = 1.0
        self.logoTop.constant = 326.5
        self.omniLeading.constant = -414
        self.parkTrailing.constant = -414
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animate()
    }
    
    func animate() {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 1.0, animations: {
            self.omniLeading.constant = 0
            self.parkTrailing.constant = 0
            self.view.layoutIfNeeded()
        }) { _ in
            UIView.animate(withDuration: 1.0, animations: {
                self.textWidth.constant = 214
                self.logoWidth.constant = 209
                self.logoTop.constant = 230
                self.view.layoutIfNeeded()
            }) { _ in
                UIView.animate(withDuration: 1.0, animations: {
                    self.topLevelConstraint.constant = -738
                    self.bottomLevelConstraint.constant = 738
                    self.view.layoutIfNeeded()
                }) { _ in
                    self.animateCompletion?()
//                    self.dismiss(animated: false, completion: nil)
                }
            }
        }
    }
}
