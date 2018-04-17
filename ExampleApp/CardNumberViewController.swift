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
    @IBOutlet weak var maxAdvancementStepper: UIStepper!
    @IBOutlet weak var numberFormatSegment: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cardNumberView.numberFormat = [4, 4, 4, 4]
        cardNumberView.text = "1234"
        
        groupPaddingStepper.value = Double(cardNumberView.groupPadding)
        groupPaddingStepper.stepValue = 1
        groupPaddingStepper.minimumValue = 0
        groupPaddingStepper.maximumValue = 20
        
        maxAdvancementStepper.value = Double(cardNumberView.maxAdvancement)
        maxAdvancementStepper.stepValue = 1
        maxAdvancementStepper.minimumValue = 5
        maxAdvancementStepper.maximumValue = 15
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
    
    @IBAction func numberFormatChanged(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: cardNumberView.numberFormat = [4, 4, 4, 4]
        case 1: cardNumberView.numberFormat = [4, 4, 4, 2]
        default: cardNumberView.numberFormat = [4, 6, 5]
        }
    }
    
    @IBAction func maxAdvancementChanged(sender: UIStepper) {
        cardNumberView.maxAdvancement = CGFloat(sender.value)
    }
}
