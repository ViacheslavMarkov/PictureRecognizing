//
//  FrameView.swift
//  PictureRecognizing
//
//  Created by Viacheslav Markov on 03.04.2023.
//

import UIKit

final class FrameView: UIView {
    let borderColor: UIColor
    let borderRadius: CGFloat
    let borderWidth: CGFloat

    init(
        borderColor: UIColor = UIColor.black,
        borderRadius: CGFloat = 4,
        borderWidth: CGFloat = 3
    ) {
        self.borderColor = borderColor
        self.borderRadius = borderRadius
        self.borderWidth = borderWidth
        
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.cgColor
        self.layer.cornerRadius = borderRadius
        self.backgroundColor = .clear
    }
}
