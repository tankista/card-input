//
//  RootViewController.swift
//  CardInput
//
//  Created by Peter Stajger on 17/04/2018.
//  Copyright © 2018 UITouch. All rights reserved.
//

import UIKit
import CardInput

class CardInputViewController: UIViewController {

    @IBOutlet weak var cardInput: CardInputView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardInput.delegate = self
    }

}

extension CardInputViewController : CardInputViewDelegate {
    
    func cardInputView(_ view: CardInputView, validateInput: String?, forEditingState state: CardInputView.EditingState) -> Bool {
        switch state {
            
        case .number:
            return PaymentCard.Number(validateInput ?? "").isValid
            
        case .expiration:
            return PaymentCard.Expiration(validateInput ?? "").isValid
            
        default:
            return true
        }
    }
    
    func cardInputView(_ view: CardInputView, determineCardTraitsFor partialCardNumber: String) -> (PaymentMethodType, [Int], Int) {
        return PaymentCard.Traits.traitsForNumber(partialCardNumber)
    }
    
    func cardInputViewDidFinishWithCard(_ view: CardInputView) {
        print("finito")
    }
    
}

