//
//  LoginViewController.swift
//  Videos
//
//  Created by Florian on 14/04/16.
//  Copyright © 2016 Chris Eidhof. All rights reserved.
//

import UIKit

public enum ContentElement {
    case label(String, UIFontTextStyle, NSTextAlignment)
    case styledLabel(NSAttributedString)
    case textView(NSAttributedString)
    case custom(UIView)
    case button(title: String, callback: () -> ())

    public init(text: String, style: UIFontTextStyle = .body, alignment: NSTextAlignment = .left) {
        self = .label(text, style, alignment)
    }
}

public final class ButtonWithTarget: UIButton {
    public var onPrimaryActionTriggered: (() -> ())? {
        didSet {
            addTarget(self, action: #selector(tapped(_:)), for: .primaryActionTriggered)
        }
    }
    
    func tapped(_ sender: AnyObject) {
        onPrimaryActionTriggered?()
    }
}

extension ContentElement {
    public var view: UIView {
        switch self {
        case .label(let text, let style, let alignment):
            let label = UILabel()
            label.text = text
            label.font = UIFont.preferredFont(forTextStyle: style)
            label.textAlignment = alignment
            label.numberOfLines = 0
            return label
        case .styledLabel(let text):
            let label = UILabel()
            label.attributedText = text
            label.numberOfLines = 0
            return label
        case .textView(let text):
            let textView = UITextView()
            #if !os(tvOS)
            textView.isEditable = false
            #endif
            textView.attributedText = text
            return textView
        case .button(let text, let callback):
            let button = ButtonWithTarget(type: .system)
            button.setTitle(text, for: .normal)
            button.onPrimaryActionTriggered = callback
            return button
        case .custom(let view):
            return view
        }
    }
}

extension UIStackView {
    public convenience init(axis: UILayoutConstraintAxis = .vertical, spacing: CGFloat = 20, distribution: UIStackViewDistribution = .fill, content: [ContentElement]) {
        self.init()
        self.axis = axis
        self.spacing = spacing
        self.distribution = distribution
        for element in content {
            addArrangedSubview(element.view)
        }
    }
}
