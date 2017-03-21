//
//  Extensions.swift
//  Videos
//
//  Created by Florian on 07/04/16.
//  Copyright © 2016 Chris Eidhof. All rights reserved.
//

import AVFoundation
import UIKit

extension URL {
    public subscript(queryItem name: String) -> String? {
        get {
            guard let items = URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems,
                let index = items.index(where: { $0.name == name }) else { return nil }
            return items[index].value
        }
        set {
            guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
                // Silently fail if we can't convert the URL to URLComponents
                return
            }
            let newItem = URLQueryItem(name: name, value: newValue)
            if let index = components.queryItems?.index(where: { $0.name == name }) {
                // Found a query item with this name
                components.queryItems?[index] = newItem
            } else if components.queryItems != nil {
                // Query item with this name not found, but queryItems array exists
                components.queryItems?.append(newItem)
            } else {
                // queryItems array doesn't exist yet
                components.queryItems = [newItem]
            }
            if let newURL = components.url {
                self = newURL
            }
        }
    }
}

extension UIViewController {
    public func addChildViewController(_ childViewController: UIViewController, to stackView: UIStackView) {
        assert(stackView.isDescendant(of: view))
        addChildViewController(childViewController)
        stackView.addArrangedSubview(childViewController.view)
        childViewController.didMove(toParentViewController: self)
    }
}

extension UIView {
    public func constrainEqual(_ attribute: NSLayoutAttribute, to: AnyObject, multiplier: CGFloat = 1, constant: CGFloat = 0) {
        constrainEqual(attribute, to: to, attribute, multiplier: multiplier, constant: constant)
    }
    
    public func constrainEqual(_ attribute: NSLayoutAttribute, to: AnyObject, _ toAttribute: NSLayoutAttribute, multiplier: CGFloat = 1, constant: CGFloat = 0) {
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: to, attribute: toAttribute, multiplier: multiplier, constant: constant)
            ]
        )
    }

    public func constrainEdges(to other: UILayoutGuide) {
        topAnchor.constrainEqual(other.topAnchor)
        bottomAnchor.constrainEqual(other.bottomAnchor)
        leadingAnchor.constrainEqual(other.leadingAnchor)
        trailingAnchor.constrainEqual(other.trailingAnchor)
    }

    public func constrainEdges(toMarginOf view: UIView) {
        constrainEqual(.top, to: view, .topMargin)
        constrainEqual(.leading, to: view, .leadingMargin)
        constrainEqual(.trailing, to: view, .trailingMargin)
        constrainEqual(.bottom, to: view, .bottomMargin)
    }
    
    /// If the `view` is nil, we take the superview.
    public func center(inView view: UIView? = nil) {
        guard let container = view ?? self.superview else { fatalError() }
        centerXAnchor.constrainEqual(container.centerXAnchor)
        centerYAnchor.constrainEqual(container.centerYAnchor)
    }

    public var debugBorder: UIColor? {
        get { return layer.borderColor.map { UIColor(cgColor: $0) } }
        set {
            layer.borderColor = newValue?.cgColor
            layer.borderWidth = newValue != nil ? 1 : 0
        }
    }

    public static func activateDebugBorders(_ views: [UIView]) {
        let colors: [UIColor] = [.magenta, .orange, .green, .blue, .red]
        for (view, color) in zip(views, colors.cycled()) {
            view.debugBorder = color
        }
    }
}

extension NSLayoutAnchor {
    func constrainEqual(_ anchor: NSLayoutAnchor<AnchorType>, constant: CGFloat = 0) {
        let constraint = self.constraint(equalTo: anchor, constant: constant)
        constraint.isActive = true
    }
}

extension NSAttributedString {
    public var mutable: NSMutableAttributedString {
        return mutableCopy() as! NSMutableAttributedString
    }
    
    public var range: NSRange {
        return NSRange(location: 0, length: (string as NSString).length)
    }
    
    public convenience init(string: String, alignment: NSTextAlignment) {
        let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        style.alignment = alignment
        self.init(string: string, attributes: [NSParagraphStyleAttributeName: style])
    }
}

public func +(lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
    let result = lhs.mutable
    result.append(rhs)
    return result
}

extension Array where Element: NSAttributedString {
    public func join(_ separator: String) -> NSAttributedString {
        return join(NSAttributedString(string: separator))
    }
    
    public func join(_ separator: NSAttributedString = NSAttributedString()) -> NSAttributedString {
        guard !isEmpty else { return NSAttributedString() }
        
        let result = self[0].mutable
        for string in dropFirst() {
            result.append(separator)
            result.append(string)
        }
        return result
    }
}

extension Sequence {
    public func failingFlatMap<T>(_ transform: (Self.Iterator.Element) throws -> T?) rethrows -> [T]? {
        var result: [T] = []
        for element in self {
            guard let transformed = try transform(element) else { return nil }
            result.append(transformed)
        }
        return result
    }

    /// Returns a sequence that repeatedly cycles through the elements of `self`.
    public func cycled() -> AnySequence<Iterator.Element> {
        return AnySequence { _ -> AnyIterator<Iterator.Element> in
            var iterator = self.makeIterator()
            return AnyIterator {
                if let next = iterator.next() {
                    return next
                } else {
                    iterator = self.makeIterator()
                    return iterator.next()
                }
            }
        }
    }
}

public func mainQueue(_ block: @escaping () -> ()) {
    DispatchQueue.main.async(execute: block)
}


extension Data {
    public var hexadecimalString: String {
        return map { String(format: "%02x", $0) }.joined(separator: "")
    }

    func sha1() -> Data {
        var digestData = Data(count: Int(CC_SHA1_DIGEST_LENGTH))
        _ = digestData.withUnsafeMutableBytes { digestBytes in
            self.withUnsafeBytes {
                _ = CC_SHA1($0, CC_LONG(self.count), digestBytes)
            }
        }
        return digestData
    }
}

extension String {
    func sha1() -> String {
        return self.data(using: .utf8)!.sha1().hexadecimalString
    }
}

public extension AVMetadataItem {
    /// - parameter language: The default is "und" ("undefined"), which is the fallback value for all languages that don't have a specific value set.
    /// - note: An initializer would be better for this, but it's not possible to write a "factory" initializer that internally instantiates a AVMutableMetadataItem (cannot assign to self).
    static func item(identifier: String, value: String?, language: String = "und") -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as NSString?
        item.extendedLanguageTag = language
        return item.copy() as! AVMetadataItem
    }

    static func item(identifier: String, image: UIImage?, language: String = "und") -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        if let image = image {
            item.value = UIImagePNGRepresentation(image) as NSData?
        } else {
            item.value = nil
        }
        item.dataType = kCMMetadataBaseDataType_PNG as String
        item.extendedLanguageTag = language
        return item.copy() as! AVMetadataItem
    }
}
