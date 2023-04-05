//
//  FooterView.swift
//  PictureRecognizing
//
//  Created by Viacheslav Markov on 04.04.2023.
//

import UIKit

protocol FooterViewDelegating: AnyObject {
    func didTapTitle(_ sender: FooterView)
}

final class FooterView: UIView {
    private let title: String
    private let viewHeight: CGFloat
    
    weak var delegate: FooterViewDelegating?
    
    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .customFont(type: .semiBold, size: 24)
        l.textColor = .black
        l.textAlignment = .center
        l.numberOfLines = 1
        return l
    }()

    init(
        title: String = "Descriptions",
        viewHeight: CGFloat = 64
    ) {
        self.title = title
        self.viewHeight = viewHeight
        
        super.init(frame: .zero)
        
        setup()
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = .white
        set(cornerRadius: 16)
    }
    
    private func setup() {
        add([
            titleLabel,
        ])
        
        let heightConstant: CGFloat = viewHeight / 2
        let spacing: CGFloat = 8
        
        NSLayoutConstraint.activate([
            self.height.constraint(equalToConstant: viewHeight),
            
            titleLabel.top.constraint(equalTo: top, constant: spacing),
            titleLabel.centerX.constraint(equalTo: centerX),
            titleLabel.leading.constraint(equalTo: leading, constant: spacing * 2),
            titleLabel.trailing.constraint(equalTo: trailing, constant: -spacing * 2),
            titleLabel.height.constraint(equalToConstant: heightConstant)
        ])
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(titleLabelTapped))
        titleLabel.addGestureRecognizer(gesture)
    }
    
    @objc
    private func titleLabelTapped(_ sender: UIView) {
        delegate?.didTapTitle(self)
    }
    
    private func configureUI() {
        titleLabel.text = title
    }
    
    func updateTitle(with text: String) {
        titleLabel.text = text
    }
}
