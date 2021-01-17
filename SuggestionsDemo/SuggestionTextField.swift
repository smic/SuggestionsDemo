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

struct SuggestionTextField<V: Equatable>: NSViewRepresentable {
    @Binding var text: String
    @ObservedObject var model: SuggestionsModel<V>
	
	func makeNSView(context: Context) -> NSSearchField {
		let searchField = NSSearchField(frame: .zero)
		searchField.controlSize = .regular
		searchField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: searchField.controlSize))
		searchField.translatesAutoresizingMaskIntoConstraints = false
		searchField.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(rawValue: 1), for: .horizontal)
		searchField.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 1), for: .horizontal)
		searchField.delegate = context.coordinator
		
		let searchFieldCell = searchField.cell!
		searchFieldCell.lineBreakMode = .byWordWrapping
		
		context.coordinator.searchField = searchField
		
		return searchField
	}
	
	func updateNSView(_ searchField: NSSearchField, context: Context) {
        let model = self.model
        let text = self.text
        
        let coordinator = context.coordinator
        coordinator.model = model
        
        coordinator.updatingSelectedRange = true
        defer {
            coordinator.updatingSelectedRange = false
        }
        
        if let selectedSuggestion = model.selectedSuggestion {
            let suggestionText = selectedSuggestion.text
            
            if searchField.stringValue != suggestionText {
                searchField.stringValue = suggestionText
            }
            
            if let fieldEditor = searchField.window?.fieldEditor(false, for: searchField) {
                if model.suggestionConfirmed {
                    let range = NSRange(suggestionText.startIndex..<suggestionText.endIndex, in: fieldEditor.string)
                    if fieldEditor.selectedRange != range {
                        fieldEditor.selectedRange = range
                    }
                } else if suggestionText.hasPrefix(text) {
                    let range = NSRange(suggestionText.index(suggestionText.startIndex, offsetBy: text.count)..<suggestionText.index(suggestionText.startIndex, offsetBy: suggestionText.count), in: fieldEditor.string)
                    if fieldEditor.selectedRange != range {
                        fieldEditor.selectedRange = range
                    }
                }
            }
        } else {
            if searchField.stringValue != self.text {
                searchField.stringValue = self.text
            }
        }
	}
	
	func makeCoordinator() -> Coordinator {
        return Coordinator(text: self.$text, model: self.model)
	}
    
	class Coordinator: NSObject, NSSearchFieldDelegate, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
		@Binding var text: String
        var model: SuggestionsModel<V>
        var didChangeSelectionSubscription: AnyCancellable?
        var frameDidChangeSubscription: AnyCancellable?
        var updatingSelectedRange: Bool = false
		
		init(text: Binding<String>, model: SuggestionsModel<V>) {
			self._text = text
            self.model = model
            
            super.init()
            
            self.didChangeSelectionSubscription = NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)
                .sink(receiveValue: { notification in
                    guard !self.updatingSelectedRange,
                          let fieldEditor = self.searchField.window?.fieldEditor(false, for: self.searchField),
                          let textView = notification.object as? NSTextView,
                          fieldEditor === textView else {
                        return
                    }
                    self.model.chooseSuggestion(nil)
                })
		}
		
        var searchField: NSSearchField! {
            didSet {
                if let searchField = self.searchField {
                    searchField.postsFrameChangedNotifications = true
                    self.frameDidChangeSubscription = NotificationCenter.default.publisher(for: NSView.frameDidChangeNotification, object: searchField)
                        .sink(receiveValue: { (_) in
                            self.model.width = self.searchField.frame.width
                        })
                } else {
                    self.frameDidChangeSubscription = nil
                }
            }
        }

		// MARK: - NSSearchField Delegate Methods
        
		@objc func controlTextDidChange(_ notification: Notification) {
            let text = self.searchField.stringValue
			
            self.model.modifiedText(text)
		}
        
        func controlTextDidEndEditing(_ obj: Notification) {
            self.model.cancel()
        }
		
		@objc func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
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
                guard self.model.suggestionsVisible else {
                    return false
                }
                self.model.cancel()
				
				return true
			}
			
			if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let suggestion = self.model.selectedSuggestion {
                    self.model.confirmSuggestion(suggestion)
                }
				
				return true
			}
			
			return false
		}
	}
}
