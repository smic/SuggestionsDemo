//
//  SMSuggestionTextField.swift
//  PubChemDemo
//
//  Created by Stephan Michels on 27.08.20.
//  Copyright © 2020 Stephan Michels. All rights reserved.
//

import AppKit
import SwiftUI

struct SMSuggestionTextField: NSViewRepresentable {
	@Binding var text: String
	var suggestions: [SMSuggestion]
	
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
		textField.stringValue = self.text
		
		let coordinator = context.coordinator
		
		let suggestions = self.suggestions
		let suggestionsController = coordinator.suggestionsController
		suggestionsController.suggestions = suggestions
		
		print("coordinator.editing: \(coordinator.editing)")
		if !suggestions.isEmpty && coordinator.editing {
			print("start with \(suggestions.count)")
			
			// We have at least 1 suggestion. Update the field editor to the first suggestion and show the suggestions window.
			if let window = suggestionsController.window, !window.isVisible {
				suggestionsController.begin(for: textField)
			}
		} else {
			print("cancel")
			
			// No suggestions. Cancel the suggestion window.
			suggestionsController.cancel()
		}
	}
	
	func makeCoordinator() -> Coordinator {
		return Coordinator(text: self.$text)
	}
	
	class Coordinator: NSObject, NSTextFieldDelegate {
		@Binding var text: String
		
		var updatingText: Bool = false
		var editedText: String = ""
		var editing: Bool = false  {
			didSet {
				print("change editing to \(self.editing)")
			}
		}
		
		init(text: Binding<String>) {
			self._text = text
		}
		
		var textField: NSTextField!

		lazy var suggestionsController: SMSuggestionsWindowController = {
			let suggestionsController = SMSuggestionsWindowController()
            suggestionsController.onSelectSuggestionItem = { [weak self] item in
                guard let self = self else {
                    return
                }
                print("item: \(item?.title ?? "nil")")
                self.updatingText = true
                defer { self.updatingText = false }
                
                let textField = self.textField!
                if let item = item {
                    let text = item.text
                    
                    textField.stringValue = text
                    if text.hasPrefix(self.editedText),
                       let fieldEditor = textField.window?.fieldEditor(false, for: self.textField) {
                        let string = fieldEditor.string
                        fieldEditor.selectedRange = NSRange(string.index(string.startIndex, offsetBy: self.editedText.count)..<string.index(string.startIndex, offsetBy: text.count), in: fieldEditor.string)
                    }
                } else {
                    textField.stringValue = self.editedText
                }
            }
			return suggestionsController
		} ()
		
		// MARK: - NSTextField Delegate Methods
		
		@objc func controlTextDidChange(_ notification: Notification) {
			guard !self.updatingText else {
				print("skip")
				return
			}
			guard let fieldEditor = self.textField.window?.fieldEditor(false, for: control) else {
				return
			}
			
			let string = fieldEditor.string
			print("controlTextDidChange: \"\(string)\"")
			
			self.editedText = string
			self.editing = true
			
			self.text = string
		}
		
	//	- (void)textFieldDidBecomeFirstResponder:(SMFocusNotifyingTextField *)textField
	//	{
	//	self.currentTextField = textField;
	//	NSTextField *lastField = self.textFields.lastObject;
	//	if (textField == lastField) {
	//	[self addTextField];
	//	}
	//	[self validateFieldsAndButtons];
	//	}
		
		@objc func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
			if commandSelector == #selector(NSResponder.moveUp(_:)) {
				// Move up in the suggested selections list
				self.suggestionsController.moveUp(textView)
//				let string = self.textField.stringValue
//				self.text = string
				return true
			}
			
			if commandSelector == #selector(NSResponder.moveDown(_:)) {
				// Move down in the suggested selections list
				self.suggestionsController.moveDown(textView)
//				let string = self.textField.stringValue
//				self.text = string
				return true
			}
			
			if commandSelector == #selector(NSResponder.deleteForward(_:)) ||
				commandSelector == #selector(NSResponder.deleteBackward(_:)) {
				/* The user is deleting the highlighted portion of the suggestion or more. Return NO so that the field editor performs the deletion. The field editor will then call -controlTextDidChange:. We don't want to provide a new set of suggestions as that will put back the characters the user just deleted. Instead, set skipNextSuggestion to YES which will cause -controlTextDidChange: to cancel the suggestions window. (see -controlTextDidChange: above)
				*/
				//        self.skipNextSuggestion = YES;
				return false
			}
			
			if commandSelector == #selector(NSResponder.complete(_:)) {
				// The user has pressed the key combination for auto completion. AppKit has a built in auto completion. By overriding this command we prevent AppKit's auto completion and can respond to the user's intention by showing or cancelling our custom suggestions window.
				
				self.editing = false
				
				return true
			}
			
			if commandSelector == #selector(NSResponder.insertNewline(_:)) {
				let string = self.textField.stringValue
				self.text = string
				
				self.editing = false
				
				return true
			}
			
			if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
				self.editing = false
				
				return true
			}
			
			// This is a command that we don't specifically handle, let the field editor do the appropriate thing.
			return false
		}
	}
}
