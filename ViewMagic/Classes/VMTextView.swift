//
//  VMTextView.swift
//  Pods
//
//  Created by Whitney Foster on 9/29/16.
//
//

import Foundation
import UIKit

public class VMTextView: UITextView {
    private var linkAttributes = [String: Any]()
    private var normalAttributes = [String: Any]()
    private var formatedAttributedString = NSMutableAttributedString()
    private let instructionsAttributeName = "WFInstructions"
    private var tapAction: ((String) -> Void)?
    
    // temps for formatting
    private var linkName = ""
    private var linkInstructions = ""
    private var foundChars = [String]()
    private var formattedString = ""
    
    enum LinkIdentifier: String {
        case opening = "["
        case breaker = ":"
        case space = " "
        case closing = "]"
    }
    
    func configure(string: String, normalAttributes: [String: Any] = [String: Any](), linkAttributes: [String: Any] = [String: Any](), tapAction: ((String) -> Void)? = nil) {
        self.isEditable = false
        self.isSelectable = false
        self.isScrollEnabled = false
        self.isUserInteractionEnabled = true
        self.backgroundColor = UIColor.clear
        self.normalAttributes = normalAttributes
        self.linkAttributes = linkAttributes
        self.tapAction = tapAction
        self.formatToAttributedStringWithLinks(text: string)
        self.attributedText = self.formatedAttributedString
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(VMTextView.tappedTextView(gr:))))
    }
    
    private func foundLink() {
        foundChars = [String]()
        linkAttributes[instructionsAttributeName] = link
        formatedAttributedString.append(NSAttributedString(string: linkName, attributes: linkAttributes))
        formattedString = ""
        linkInstructions = ""
        linkName = ""
    }
    
    private func foundLetter(letter: String) {
        switch foundChars.count {
        case 1:
            // looking for linkName
            self.linkName.append(letter)
            break
        case 2:
            // looking for space but no space given
            break
        case 3:
            // looking for link
            self.linkInstructions.append(letter)
            break
        default:
            self.formattedString.append(letter)
        }
    }
    
    private func foundLinkId(letter: LinkIdentifier) {
        switch letter {
        case .opening:
            // save what you have, start looking for linkName
            foundChars = [letter.rawValue]
            linkInstructions = ""
            linkName = ""
            formatedAttributedString.append(NSAttributedString(string: formattedString, attributes: normalAttributes))
            break
        case .breaker:
            if foundChars.count == 1 {
                // done finding linkName
                foundChars.append(letter.rawValue)
            }
            else {
                foundLetter(letter: letter.rawValue)
            }
            break
        case .space:
            if foundChars.count == 2 {
                // start finding link
                foundChars.append(letter.rawValue)
            }
            else {
                foundLetter(letter: letter.rawValue)
            }
            break
        case .closing:
            if foundChars.count == 3 {
                // done finding link
                foundLink()
            }
            else {
                foundLetter(letter: letter.rawValue)
            }
            break
        }
    }
    
    private func formatToAttributedStringWithLinks(text t: String) {
        formatedAttributedString = NSMutableAttributedString()
        formattedString = ""
        linkInstructions = ""
        linkName = ""
        for c in t.characters.map({"\($0)"}) {
            if let linkId = LinkIdentifier(rawValue: c) {
                foundLinkId(letter: linkId)
            }
            else {
                foundLetter(letter: c)
            }
        }
        formatedAttributedString.append(NSAttributedString(string: formattedString, attributes: normalAttributes))
    }
    
    internal func tappedTextView(gr: UITapGestureRecognizer) {
        let tap = gr.location(in: gr.view ?? self)
        if var pos1 = self.closestPosition(to: tap), var pos2 = self.position(from: pos1, offset: 1) {
            if let behindPos1 = self.position(from: pos1, offset: -1), let behindPos2 = self.position(from: pos2, offset: -1) {
                pos1 = behindPos1
                pos2 = behindPos2
                
                if let range = self.textRange(from: pos1, to: pos2) {
                    let startOffset = self.offset(from: self.beginningOfDocument, to: range.start)
                    let endOffset = self.offset(from: self.beginningOfDocument, to: range.end)
                    
                    let offsetRange = NSMakeRange(startOffset, endOffset-startOffset)
                    if offsetRange.location != NSNotFound && offsetRange.length != 0 && NSMaxRange(offsetRange) <= self.attributedText.length {
                        let formatedAttributedString = self.attributedText.attributedSubstring(from: offsetRange)
                        if let instructions = formatedAttributedString.attribute(instructionsAttributeName, at: 0, effectiveRange: nil) as? String {
                            self.tapAction?(instructions)
                        }
                    }
                }
            }
            
        }
        
    }
}
