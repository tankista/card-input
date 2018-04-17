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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cardNumberView.text = "1234"
        
    }
    
    @IBAction func editingChanged(sender: UISwitch) {
        if sender.isOn {
            _ = cardNumberView.becomeFirstResponder()
        }
        else {
            _ = cardNumberView.resignFirstResponder()
        }
    }
    
}
