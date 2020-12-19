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
        
//        print("model.selectedSuggestionIndex: \(model.selectedSuggestionIndex)")
        if let selectedSuggestionIndex = model.selectedSuggestionIndex,
           case let .item(item) = model.suggestions[selectedSuggestionIndex] {
            print("text: \(text) item.text: \(item.text)")
            let itemText = item.text
            
            if textField.stringValue != itemText {
                print("1.OLD: \"\(textField.stringValue)\" NEW: \"\(item.text)\"")
                textField.stringValue = itemText
            }
            
            if item.text.hasPrefix(text),
               let fieldEditor = textField.window?.fieldEditor(false, for: textField) {
                let range = NSRange(itemText.index(itemText.startIndex, offsetBy: text.count)..<itemText.index(itemText.startIndex, offsetBy: itemText.count), in: fieldEditor.string)
                if fieldEditor.selectedRange != range {
                    fieldEditor.selectedRange = range
                }
            }
        } else {
            if textField.stringValue != self.text {
                print("2.OLD: \"\(textField.stringValue)\" NEW: \"\(self.text)\"")
                textField.stringValue = self.text
            }
        }
        
		
		

//		print("coordinator.editing: \(coordinator.editing)")
//        print("model.suggestionsVisible: \(model.suggestionsVisible)")
        /*if !model.suggestions.isEmpty && model.textEdited && !model.suggestionConfirmed {
//            print("start with \(model.suggestions.count)")
			
			// We have at least 1 suggestion. Update the field editor to the first suggestion and show the suggestions window.
            if !model.suggestionsVisible {
                model.showSuggestions()
			}
		} else {
//			print("cancel")
			
			// No suggestions. Cancel the suggestion window.
            if model.suggestionsVisible {
                model.cancel()
            }
		}*/
	}
	
	func makeCoordinator() -> Coordinator {
        return Coordinator(text: self.$text, model: self.model)
	}
    
	class Coordinator: NSObject, NSTextFieldDelegate, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
		@Binding var text: String
        var model: SuggestionsModel
        var didChangeSelectionSubscription: AnyCancellable?
        var pressedDelete: Bool = false
        var updatingSelectedRange: Bool = false
		
		init(text: Binding<String>, model: SuggestionsModel) {
			self._text = text
            self.model = model
            
            super.init()
            
//            self.model.onChoose = { [weak self] (suggestionIndex, suggestionItem) in
//                self?.chooseSuggestion(index: suggestionIndex, item: suggestionItem)
//            }
//            self.model.onConfirm = { [weak self] (suggestionIndex, suggestionItem) in
//                self?.confirmSuggestion(index: suggestionIndex, item: suggestionItem)
//            }
            
            self.didChangeSelectionSubscription = NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)
                .sink(receiveValue: { notification in
                    guard !self.updatingSelectedRange,
                          let fieldEditor = self.textField.window?.fieldEditor(false, for: self.textField),
                          let textView = notification.object as? NSTextView,
                          fieldEditor === textView else {
                        return
                    }
                    print("selectionRange: \(fieldEditor.selectedRange), text: \(fieldEditor.string)")
                    if self.model.suggestionConfirmed {
                        self.model.suggestionConfirmed = false
                    }
                    if self.model.selectedSuggestionIndex != nil {
                        self.model.selectedSuggestionIndex = nil
                    }
                })

		}
		
		var textField: NSTextField!

//        private func ensureFocus() {
////            let _ = self.ensureFocus(self.hostingController.view)
//            for subview in self.hostingController.view.subviews {
//                if self.ensureFocus(subview) {
//                    return
//                }
//            }
//        }
//
//        private func ensureFocus(_ view: NSView) -> Bool {
//            if view.canBecomeKeyView {
//                print("make focus: \(view)")
//                print("is table view: \(view is NSTableView)")
//                view.window?.makeFirstResponder(view)
//                return true
//            }
//
//            for subview in view.subviews {
//                if self.ensureFocus(subview) {
//                    return true
//                }
//            }
//            return false
//        }
        
//        private func findTableView(_ view: NSView) -> NSTableView? {
//            if let tableView = view as? NSTableView {
//                return tableView
//            }
//            for subview in view.subviews {
//                if let tableView = self.findTableView(subview) {
//                    return tableView
//                }
//            }
//            return nil
//        }
		
		// MARK: - NSTextField Delegate Methods
        
        /*@objc func controlTextDidBeginEditing(_ notification: Notification) {
            guard let fieldEditor = self.textField.window?.fieldEditor(false, for: control) else {
                return
            }
            
//            self.didChangeSelectionSubscription = NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification, object: fieldEditor)
//                .sink(receiveValue: { (_) in
//                    print("selectionRange: \(fieldEditor.selectedRange)")
//                    self.model.suggestionConfirmed = false
//                })
//            print("delegate: \(fieldEditor.delegate)")
        }*/
		
		@objc func controlTextDidChange(_ notification: Notification) {
//			guard !self.updatingText else {
//				print("skip")
//				return
//			}
			guard let fieldEditor = self.textField.window?.fieldEditor(false, for: control) else {
				return
			}
			
			let text = fieldEditor.string
            print("controlTextDidChange: \"\(text)\", selectedRange: \(fieldEditor.selectedRange)")
			
//			self.editedText = string
//			self.editing = true
			
            self.model.modifiedText(text: text, binding: self.$text)
            /*
            if self.pressedDelete {
//                self.model.delete(text: string, binding: self.$text)
                self.text = text
                self.model.textEdited = false
                
                self.model.selectedSuggestionIndex = nil
//                self.suggestionsVisible = true
                
            } else {
                self.text = text
                self.model.textEdited = false
                
                if let (itemIndex, item) = self.model.firstItem,
                   item.text.hasPrefix(text),
                   fieldEditor.selectedRange.location == text.utf16.count {
                    self.model.selectedSuggestionIndex = itemIndex
                } else {
                    self.model.selectedSuggestionIndex = nil
                }
                
//                self.model.modifiedText(text: string, binding: self.$text)
            }
            
            self.model.suggestionsVisible = true
            
            self.model.suggestionConfirmed = false*/
		}
        
        func controlTextDidEndEditing(_ obj: Notification) {
            /* If the suggestionController is already in a cancelled state, this call does nothing and is therefore always safe to call.
            */
            self.model.cancel()
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
            print("doCommandBy: \(commandSelector)")
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
				// Move down in the suggested selections list
                self.model.moveDown()
				return true
			}
			
			/*if commandSelector == #selector(NSResponder.deleteForward(_:)) ||
				commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                if self.model.selectedSuggestionIndex != nil {
                    //self.model.selectedSuggestionIndex = nil
                    self.model.chooseSuggestion(index: nil, item: nil)
                    return true
                }
                self.pressedDelete = true
//                self.model.delete()
				return false
			}*/
			
			if commandSelector == #selector(NSResponder.complete(_:)) ||
                commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                self.model.cancel()
				
				return true
			}
			
			if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let suggestionIndex = self.model.selectedSuggestionIndex,
                   case let .item(item) = self.model.suggestions[suggestionIndex] {
//                    self.confirmSuggestion(index: suggestionIndex, item: item)
                    self.model.confirmSuggestion(index: suggestionIndex, item: item, binding: self.$text)
                }
				
//				self.model.textEdited = false
				
				return true
			}
			
			// This is a command that we don't specifically handle, let the field editor do the appropriate thing.
//            self.model.suggestionConfirmed = false
			return false
		}
	}
}
