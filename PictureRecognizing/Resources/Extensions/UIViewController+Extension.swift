//
//  UIViewController+Extension.swift
//  PictureRecognizing
//
//  Created by Viacheslav Markov on 04.04.2023.
//

import UIKit

extension UIViewController {
    var topbarHeight: CGFloat {
        return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
}
