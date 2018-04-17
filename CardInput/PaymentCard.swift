//
//  PaymentCard.swift
//  CardInput
//
//  Created by Peter Stajger on 17/04/2018.
//  Copyright © 2018 UITouch. All rights reserved.
//

import Foundation

///
/// A model object that is being used by CardInputView.
///
public struct PaymentCard : CustomStringConvertible {
    
    ///Holds number as internal storage, can determine card type
    public struct Traits {
        
        ///Returns traits for given number. If number is not recognized, default
        ///traints are returned with unknown card type.
        public static func traitsForNumber(_ number: String) -> (PaymentMethodType, [Int], Int) {
            
            let intNumber = Int(String(number.prefix(2))) ?? -1
            
            switch intNumber {
            case 40..<50:           return (.Visa,              [4, 4, 4, 4], 3)
            case 50..<60:           return (.MasterCard,        [4, 4, 4, 4], 3)
            case 34, 37:            return (.AmericanExpress,   [4, 6, 5],    4)
            case 60, 62, 64, 65:    return (.Discover,          [4, 4, 4, 4], 3)
            case 35:                return (.JCB,               [4, 4, 4, 4], 3)
            case 30, 36, 38, 39:    return (.DinersClub,        [4, 4, 4, 2], 3)
            default:                return (.Unknown,           [4, 4, 4, 4], 3)
            }
        }
    }
    
    public struct Number {
        
        public let string: String
        
        public init(_ string: String) {
            self.string = string
        }
        
        //luhn alghoritm
        public var isValid: Bool {
            var sum = 0
            for (idx, value) in string.reversed().map( { Int(String($0))! }).enumerated() {
                sum += ((idx % 2 == 1) ? (value == 9 ? 9 : (value * 2) % 9) : value)
            }
            return sum > 0 ? sum % 10 == 0 : false
        }
        
    }
    
    public struct Expiration {
        
        public let string: String
        
        public init(_ string: String) {
            self.string = string
        }
        
        public var month: String? {
            let expiration = string.split(separator: "/").map { String($0) }
            if expiration.count == 2 {
                return expiration[0]
            }
            
            return nil
        }
        
        public var year: String? {
            let expiration = string.split(separator: "/").map { String($0) }
            if expiration.count == 2 {
                return expiration[1]
            }
            return nil
        }
        
        public var isValid: Bool {
            //TODO: add validation code here
            //should check if date is in future or something (check stripe code
            return true
        }
    }
    
    fileprivate var data: (Number, Expiration, String)
    
    public var number: String {
        return data.0.string
    }
    
    public var expiration: String {
        return data.1.string
    }
    
    public var CVC: String {
        return data.2
    }
    
    ///Last group is last group of digits based on number format.
    public var lastGroup: String {
        let lastGroupIndex = Traits.traitsForNumber(number).1.last!
        return String(number.suffix(lastGroupIndex))
    }
    
    public var vendor: PaymentMethodType {
        return Traits.traitsForNumber(number).0
    }
    
    public var description: String {
        return "\(vendor) •••• \(lastGroup)"
    }
    
    public init(data: (String, String, String)) {
        self.data = (Number(data.0), Expiration(data.1), data.2)
    }
}
