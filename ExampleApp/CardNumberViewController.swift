//
//  CardNumberViewController.swift
//  ExampleApp
//
//  Created by Peter Stajger on 17/04/2018.
//  Copyright © 2018 UITouch. All rights reserved.
//

import UIKit
import CardInput

class CardNumberViewController: UIViewController {
    
    @IBOutlet weak var cardNumberView: CardNumberView!
    @IBOutlet weak var editingSwitch: UISwitch!
    @IBOutlet weak var groupPaddingStepper: UIStepper!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cardNumberView.text = "1234"
        
        groupPaddingStepper.value = Double(cardNumberView.groupPadding)
        groupPaddingStepper.stepValue = 1
        groupPaddingStepper.minimumValue = 0
        groupPaddingStepper.maximumValue = 20
    }
    
    @IBAction func editingChanged(sender: UISwitch) {
        if sender.isOn {
            _ = cardNumberView.becomeFirstResponder()
        }
        else {
            _ = cardNumberView.resignFirstResponder()
        }
    }
    
    @IBAction func groupPaddingChanged(sender: UIStepper) {
        cardNumberView.groupPadding = CGFloat(sender.value)
    }
}
