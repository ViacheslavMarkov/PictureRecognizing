//
//  UIImage+Extension.swift
//  PictureRecognizing
//
//  Created by Viacheslav Markov on 04.04.2023.
//

import UIKit

extension UIImage {
    static func image(
        name: ImageNameType,
        renderingMode: RenderingMode = .alwaysTemplate
    ) -> UIImage? {
        .init(named: name.rawValue)?
        .withRenderingMode(renderingMode)
    }
    
    static func systemImage(
        name: ImageNameType,
        renderingMode: RenderingMode = .alwaysTemplate
    ) -> UIImage? {
        .init(systemName: name.rawValue)?
        .withRenderingMode(renderingMode)
    }
}
