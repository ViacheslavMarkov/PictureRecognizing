//
//  HeaderView.swift
//  PictureRecognizing
//
//  Created by Viacheslav Markov on 04.04.2023.
//

import UIKit

protocol HeaderViewDelegating: AnyObject {
    func didTapGalleryButton(_ sender: HeaderView)
}

final class HeaderView: UIView {
    let title: String
    let viewHeight: CGFloat
    
    weak var delegate: HeaderViewDelegating?
    
    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .customFont(type: .bold, size: 32)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 1
        return l
    }()
    
    private lazy var containerImageView: UIView = {
        let v = UIView()
        v.backgroundColor = .black.withAlphaComponent(0.7)
        return v
    }()
    
    private lazy var imageView: UIImageView = {
        let i = UIImageView()
        i.image = .systemImage(name: .gallery, renderingMode: .alwaysTemplate)
        i.tintColor = .white
        return i
    }()

    init(
        title: String = "Quartz",
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
        self.backgroundColor = .black.withAlphaComponent(0.6)
        containerImageView.set(cornerRadius: viewHeight / 4)
    }
    
    private func setup() {
        containerImageView.add([
            imageView
        ])
        
        add([
            containerImageView,
            titleLabel,
        ])
        
        let heightConstant: CGFloat = viewHeight / 2
        let spacing: CGFloat = 8
        
        NSLayoutConstraint.activate([
            self.height.constraint(equalToConstant: viewHeight),
            
            titleLabel.bottom.constraint(equalTo: bottom, constant: -spacing),
            titleLabel.centerX.constraint(equalTo: centerX),
            titleLabel.height.constraint(equalToConstant: heightConstant),

            containerImageView.bottom.constraint(equalTo: bottom, constant: -spacing),
            containerImageView.leading.constraint(equalTo: leading, constant: spacing * 2),
            containerImageView.height.constraint(equalToConstant: heightConstant),
            containerImageView.width.constraint(equalTo: containerImageView.height),
            
            imageView.top.constraint(equalTo: containerImageView.top, constant: spacing),
            imageView.bottom.constraint(equalTo: containerImageView.bottom, constant: -spacing),
            imageView.leading.constraint(equalTo: containerImageView.leading, constant: spacing),
            imageView.trailing.constraint(equalTo: containerImageView.trailing, constant: -spacing),
        ])
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(containerImageViewTapped))
        containerImageView.addGestureRecognizer(gesture)
    }
    
    @objc
    private func containerImageViewTapped(_ sender: UIView) {
        delegate?.didTapGalleryButton(self)
    }
    
    func configureUI() {
        titleLabel.text = title
    }
}
