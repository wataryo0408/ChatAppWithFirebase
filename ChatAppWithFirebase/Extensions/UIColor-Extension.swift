//
//  UIColor-Extension.swift
//  ChatAppWithFirebase
//
//  Created by 渡邉凌 on 2021/01/15.
//

import Foundation
import UIKit

extension UIColor{
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}
