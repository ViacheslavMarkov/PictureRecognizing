//
//  UIFont+Extension.swift
//  PictureRecognizing
//
//  Created by Viacheslav Markov on 04.04.2023.
//

import UIKit

public extension UIFont {
    enum FontType: String {
        case bold = "Montserrat-Bold"
        case medium = "Montserrat-Medium"
        case regular = "Montserrat-Regular"
        case semiBold = "Montserrat-SemiBold"
    }

    static func customFont(
        type: FontType,
        size: CGFloat
    ) -> UIFont {
        UIFont(
            name: type.rawValue,
            size: size
        ) ?? UIFont.systemFont(ofSize: size, weight: .regular)
    }
}
