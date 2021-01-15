//
//  SuggestionTextField.swift
//  PubChemDemo
//
//  Created by Stephan Michels on 27.08.20.
//  Copyright © 2020 Stephan Michels. All rights reserved.
//

import AppKit
import SwiftUI
import Combine

// original code from https://developer.apple.com/library/archive/samplecode/CustomMenus

struct SuggestionTextField: NSViewRepresentable {
    @Binding var text: String
    @ObservedObject var model: SuggestionsModel
	
	func makeNSView(context: Context) -> NSTextField {
		let textField = NSTextField(frame: .zero)
		textField.controlSize = .regular
		textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: textField.controlSize))
		textField.translatesAutoresizingMaskIntoConstraints = false
		textField.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(rawValue: 1), for: .horizontal)
		textField.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 1), for: .horizontal)
		textField.delegate = context.coordinator
		
		let textFieldCell = textField.cell!
		textFieldCell.lineBreakMode = .byWordWrapping
		
		context.coordinator.textField = textField
		
		return textField
	}
	
	func updateNSView(_ textField: NSTextField, context: Context) {
        let model = self.model
        let text = self.text
        
        let coordinator = context.coordinator
        coordinator.model = model
        
        coordinator.updatingSelectedRange = true
        defer {
            coordinator.updatingSelectedRange = false
        }
        
        if let selectedSuggestionIndex = model.selectedSuggestionIndex,
           case let .item(item) = model.suggestions[selectedSuggestionIndex] {
            let itemText = item.text
            
            if textField.stringValue != itemText {
                textField.stringValue = itemText
            }
            
            if let fieldEditor = textField.window?.fieldEditor(false, for: textField) {
                if model.suggestionConfirmed {
                    let range = NSRange(itemText.startIndex..<itemText.endIndex, in: fieldEditor.string)
                    if fieldEditor.selectedRange != range {
                        fieldEditor.selectedRange = range
                    }
                } else if item.text.hasPrefix(text) {
                    let range = NSRange(itemText.index(itemText.startIndex, offsetBy: text.count)..<itemText.index(itemText.startIndex, offsetBy: itemText.count), in: fieldEditor.string)
                    if fieldEditor.selectedRange != range {
                        fieldEditor.selectedRange = range
                    }
                }
            }
        } else {
            if textField.stringValue != self.text {
                textField.stringValue = self.text
            }
        }
	}
	
	func makeCoordinator() -> Coordinator {
        return Coordinator(text: self.$text, model: self.model)
	}
    
	class Coordinator: NSObject, NSTextFieldDelegate, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
		@Binding var text: String
        var model: SuggestionsModel
        var didChangeSelectionSubscription: AnyCancellable?
        var frameDidChangeSubscription: AnyCancellable?
        var updatingSelectedRange: Bool = false
		
		init(text: Binding<String>, model: SuggestionsModel) {
			self._text = text
            self.model = model
            
            super.init()
            
            self.didChangeSelectionSubscription = NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)
                .sink(receiveValue: { notification in
                    guard !self.updatingSelectedRange,
                          let fieldEditor = self.textField.window?.fieldEditor(false, for: self.textField),
                          let textView = notification.object as? NSTextView,
                          fieldEditor === textView else {
                        return
                    }
                    self.model.chooseSuggestion(index: nil, item: nil)
                })
		}
		
        var textField: NSTextField! {
            didSet {
                if let textField = self.textField {
                    textField.postsFrameChangedNotifications = true
                    self.frameDidChangeSubscription = NotificationCenter.default.publisher(for: NSView.frameDidChangeNotification, object: textField)
                        .sink(receiveValue: { (_) in
                            self.model.width = self.textField.frame.width
                        })
                } else {
                    self.frameDidChangeSubscription = nil
                }
            }
        }

		// MARK: - NSTextField Delegate Methods
        
		@objc func controlTextDidChange(_ notification: Notification) {
//			guard let fieldEditor = self.textField.window?.fieldEditor(false, for: control) else {
//				return
//			}
//
//			let text = fieldEditor.string
            let text = self.textField.stringValue 
//            print("controlTextDidChange: \"\(text)\", selectedRange: \(fieldEditor.selectedRange)")
			
//			self.editedText = string
//			self.editing = true
			
            self.model.modifiedText(text: text, binding: self.$text)
		}
        
        func controlTextDidEndEditing(_ obj: Notification) {
            self.model.cancel()
        }
		
		@objc func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
//            print("doCommandBy: \(commandSelector)")
			if commandSelector == #selector(NSResponder.moveUp(_:)) {
                guard self.model.suggestionsVisible else {
                    return false
                }
                self.model.moveUp()
				return true
			}
			
			if commandSelector == #selector(NSResponder.moveDown(_:)) {
                guard self.model.suggestionsVisible else {
                    return false
                }
                self.model.moveDown()
				return true
			}
			
			if commandSelector == #selector(NSResponder.complete(_:)) ||
                commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                self.model.cancel()
				
				return true
			}
			
			if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let suggestionIndex = self.model.selectedSuggestionIndex,
                   case let .item(item) = self.model.suggestions[suggestionIndex] {
                    self.model.confirmSuggestion(index: suggestionIndex, item: item, binding: self.$text)
                }
				
				return true
			}
			
			return false
		}
	}
}
