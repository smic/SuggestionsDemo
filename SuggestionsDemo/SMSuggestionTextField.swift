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
        coordinator.model.suggestions = suggestions
//        print("set suggestions in \(coordinator.model): \(suggestions)")
		/*let suggestionsController = coordinator.suggestionsController
		suggestionsController.suggestions = suggestions*/
		
		print("coordinator.editing: \(coordinator.editing)")
		if !suggestions.isEmpty && coordinator.editing {
			print("start with \(suggestions.count)")
			
			// We have at least 1 suggestion. Update the field editor to the first suggestion and show the suggestions window.
			if let window = coordinator.window, !window.isVisible {
                coordinator.showSuggestions()
			}
		} else {
			print("cancel")
			
			// No suggestions. Cancel the suggestion window.
            coordinator.cancel()
		}
	}
	
	func makeCoordinator() -> Coordinator {
		return Coordinator(text: self.$text)
	}
    
	class Coordinator: NSObject, NSTextFieldDelegate, NSWindowDelegate {
		@Binding var text: String
        let model = SuggestionsView.Model()
		
		var updatingText: Bool = false
		var editedText: String = ""
		var editing: Bool = false  {
			didSet {
				print("change editing to \(self.editing)")
			}
		}
        
        fileprivate let hostingController: NSHostingController<AnyView>
		
		init(text: Binding<String>) {
			self._text = text
            
            let contentRect = NSRect(x: 0, y: 0, width: 20, height: 20);
            let window = NSWindow(contentRect: contentRect, styleMask: .borderless, backing: .buffered, defer: true)
            window.hasShadow = true
            window.backgroundColor = .clear
            window.isOpaque = false
            self.window = window
            
            let hostingViewController = NSHostingController(rootView: AnyView(SuggestionsView(model: self.model)))
            window.contentViewController = hostingViewController
            self.hostingController = hostingViewController
            
            super.init()
            
            window.delegate = self
            
            self.model.onChoose = { (suggestionIndex, suggestionItem) in
                self.chooseSuggestion(index: suggestionIndex, item: suggestionItem)
            }
            self.model.onConfirm = { (suggestionIndex, suggestionItem) in
                self.confirmSuggestion(index: suggestionIndex, item: suggestionItem)
            }
		}
		
		var textField: NSTextField!
        var window: NSWindow?
        private var localMouseDownEventMonitor: Any?
        private var lostFocusObserver: Any?

		/*lazy var suggestionsController: SMSuggestionsWindowController = {
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
		} ()*/
        
        fileprivate func showSuggestions() {
            guard let parentTextField = self.textField,
                  let suggestionWindow = self.window,
                  let parentWindow = parentTextField.window else {
                return
            }
            
            self.layoutSuggestions() // The height of the window will be adjusted in -layoutSuggestions.
            
            print("3.suggestionWindow.frame: \(suggestionWindow.frame)")
            
            // add the suggestion window as a child window so that it plays nice with Expose
            parentWindow.addChildWindow(suggestionWindow, ordered: .above)
            
            // keep track of the parent text field in case we need to commit or abort editing.
//            self.parentTextField = parentTextField
            
            // setup auto cancellation if the user clicks outside the suggestion window and parent text field. Note: this is a local event monitor and will only catch clicks in windows that belong to this application. We use another technique below to catch clicks in other application windows.
            self.localMouseDownEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] (event) -> NSEvent? in
                guard let self = self else {
                    return event
                }
                
                // If the mouse event is in the suggestion window, then there is nothing to do.
                if event.window != suggestionWindow {
                    if event.window == parentWindow {
                        /* Clicks in the parent window should either be in the parent text field or dismiss the suggestions window. We want clicks to occur in the parent text field so that the user can move the caret or select the search text.
                        
                            Use hit testing to determine if the click is in the parent text field. Note: when editing an NSTextField, there is a field editor that covers the text field that is performing the actual editing. Therefore, we need to check for the field editor when doing hit testing.
                        */
                        let contentView = parentWindow.contentView!
                        let locationTest = contentView.convert(event.locationInWindow, from: nil)
                        let hitView = contentView.hitTest(locationTest)
                        let fieldEditor = parentTextField.currentEditor()
                        if hitView != parentTextField,
                           let fieldEditor = fieldEditor,
                           hitView != fieldEditor {
                            // Since the click is not in the parent text field, return nil, so the parent window does not try to process it, and cancel the suggestion window.
        //                    event = nil;
                            
                            self.cancel()
                        }
                    } else {
                        // Not in the suggestion window, and not in the parent window. This must be another window or palette for this application.
                        self.cancel()
                    }
                }
                
                return event
            }
            // as per the documentation, do not retain event monitors.
            
            // We also need to auto cancel when the window loses key status. This may be done via a mouse click in another window, or via the keyboard (cmd-~ or cmd-tab), or a notificaiton. Observing NSWindowDidResignKeyNotification catches all of these cases and the mouse down event monitor catches the other cases.
            self.lostFocusObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: parentWindow, queue: nil) { [weak self] _ in
                guard let self = self else {
                    return
                }
                
                // lost key status, cancel the suggestion window
                self.cancel()
            }
        }
        
        public func cancel() {
            guard let suggestionWindow = self.window else {
                return
            }
            if suggestionWindow.isVisible {
                // Remove the suggestion window from parent window's child window collection before ordering out or the parent window will get ordered out with the suggestion window.
                suggestionWindow.parent?.removeChildWindow(suggestionWindow)
                suggestionWindow.orderOut(nil)
                
        //        // Disconnect the accessibility parent/child relationship
        //        [[(SuggestionsWindow *)suggestionWindow parentElement] setSuggestionsWindow:nil];
        //        [(SuggestionsWindow *)suggestionWindow setParentElement:nil];
            }
            
            // dismantle any observers for auto cancel
            if let lostFocusObserver = self.lostFocusObserver {
                NotificationCenter.default.removeObserver(lostFocusObserver)
                self.lostFocusObserver = nil
            }
            
            if let localMouseDownEventMonitor = self.localMouseDownEventMonitor {
                NSEvent.removeMonitor(localMouseDownEventMonitor)
                self.localMouseDownEventMonitor = nil
            }
            
            self.model.selectedSuggestionIndex = nil
        }
        
        private func layoutSuggestions() {
            guard let parentTextField = self.textField,
                  let suggestionWindow = self.window,
                  let parentWindow = parentTextField.window else {
                return
            }
            let parentFrame = parentTextField.frame
            
            
            // Place the suggestion window just underneath the text field and make it the same width as th text field.
            guard let parentTextFieldSuperview = parentTextField.superview else {
                return
            }
            var location: NSPoint
            if parentTextField.superview?.isFlipped == true {
                var origin = parentFrame.origin
                origin.y += parentFrame.size.height
                location = parentTextFieldSuperview.convert(origin, to: nil)
            }
            else {
                location = parentTextFieldSuperview.convert(parentFrame.origin, to: nil)
            }
            location = parentWindow.convertPoint(toScreen: location)
            // nudge the suggestion window down so it doesn't overlapp the parent view
            if parentTextField.focusRingType == .default {
                location.y -= 3.0
            } else {
                location.y -= 2.0
            }
            
            do {
                var frame = self.textField.frame
                print("1.frame: \(frame)")
                frame = self.textField.superview!.convert(frame, to: nil)
                print("2.frame: \(frame)")
                frame = self.textField.window!.convertToScreen(frame)
                print("3.frame: \(frame)")
            }
            
            print("1.suggestionWindow.frame: \(suggestionWindow.frame)")
            
//            suggestionWindow.setFrame(frame, display: false)
//            suggestionWindow.setFrameTopLeftPoint(location)
//            print("2.suggestionWindow.frame: \(suggestionWindow.frame)")

            // We have added all of the suggestion to the window. Now set the size of the window.
            
//            print("preferredContentSize \(self.hostingController.preferredContentSize)")
            
//            self.hostingController.view.layoutSubtreeIfNeeded()
            let contentSize = self.hostingController.sizeThatFits(in: CGSize(width: self.textField.frame.size.width, height: 500))
            
            // Don't forget to account for the extra room needed the rounded corners.
        //    NSUInteger numberOfSuggestions = self.suggestions.count;
//            var contentHeight: CGFloat = /*numberOfSuggestions * tableView.rowHeight + numberOfSuggestions * tableView.intercellSpacing.height + */ 2 * 5
            /*for rowIndex in 0..<self.numberOfRows(in: tableView) {
                contentHeight += self.tableView(tableView, heightOfRow:rowIndex)
                contentHeight += tableView.intercellSpacing.height;
            }*/
            
            var winFrame = CGRect(x: location.x,
                                  y: location.y - contentSize.height,
                                  width: contentSize.width,
                                  height: contentSize.height)
//            winFrame.origin.y = winFrame.maxY - contentSize.height
//            winFrame.size.height = contentSize.height;
            if suggestionWindow.frame != winFrame {
                suggestionWindow.setFrame(winFrame, display: false)
            }
            
            print("content size: \(contentSize)")
            print("winFrame: \(winFrame)")
        }
        
        fileprivate func moveUp() {
            guard let selectedRow = self.model.selectedSuggestionIndex else {
                return
            }

            guard let (index, item) = self.previousItemRow(for: selectedRow) else {
                self.model.selectedSuggestionIndex = nil
                self.chooseSuggestion(index: nil, item: nil)
                return
            }
            self.model.selectedSuggestionIndex = index
            self.chooseSuggestion(index: index, item: item)
        }

        /* move the selection down and send action.
        */
        fileprivate func moveDown() {
            guard let selectedIndex = self.model.selectedSuggestionIndex else {
                guard let (index, item) = self.firstItem else {
                    return
                }
                self.model.selectedSuggestionIndex = index
                self.chooseSuggestion(index: index, item: item)
                return
            }
            
            guard let (index, item) = self.nextItem(for: selectedIndex) else {
                return
            }
            self.model.selectedSuggestionIndex = index
            self.chooseSuggestion(index: index, item: item)
        }
        
        private var firstItem: (Int, SMSuggestionItem)? {
            let suggestions = self.model.suggestions
            guard !suggestions.isEmpty else {
                return nil
            }
            
            for (currentRow, suggestion) in suggestions.enumerated() {
                if case let .item(item) = suggestion {
                    return (currentRow, item)
                }
            }
            return nil;
        }

        private func nextItem(for index: Int) -> (Int, SMSuggestionItem)? {
            let suggestions = self.model.suggestions
            guard 0 <= index || index < suggestions.count else {
                return nil
            }
            
            for (currentIndex, suggestion) in suggestions.enumerated() {
                guard currentIndex > index else {
                    continue
                }
                if case let .item(currentItem) = suggestion {
                    return (currentIndex, currentItem)
                }
            }
            return nil
        }

        private func previousItemRow(for index: Int) -> (Int, SMSuggestionItem)? {
            let suggestions = self.model.suggestions
            guard 0 <= index || index < suggestions.count else {
                return nil
            }
            
            for (currentIndex, suggestion) in suggestions.enumerated().reversed() {
                guard currentIndex < index else {
                    continue
                }
                if case let .item(item) = suggestion {
                    return (currentIndex, item)
                }
            }
            return nil
        }
        
        private func chooseSuggestion(index: Int?, item: SMSuggestionItem?) {
            guard let textField = self.textField else {
                return
            }
            guard let item = item else {
                textField.stringValue = self.editedText
                return
            }
            let text = item.text
            
            textField.stringValue = text
            
            if text.hasPrefix(self.editedText),
               let fieldEditor = textField.window?.fieldEditor(false, for: self.textField) {
                let string = fieldEditor.string
                fieldEditor.selectedRange = NSRange(string.index(string.startIndex, offsetBy: self.editedText.count)..<string.index(string.startIndex, offsetBy: text.count), in: fieldEditor.string)
            }
        }
        
        private func confirmSuggestion(index: Int, item: SMSuggestionItem) {
            guard let textField = self.textField else {
                return
            }
            let text = item.text
            
            textField.stringValue = text
            
            if let fieldEditor = textField.window?.fieldEditor(false, for: self.textField) {
                let string = fieldEditor.string
                fieldEditor.selectedRange = NSRange(string.endIndex..<string.endIndex, in: fieldEditor.string)
            }

            self.editing = false
            
            self.cancel()
            
            self.text = text
        }
		
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
                guard self.editing else {
                    return false
                }
				// Move up in the suggested selections list
//				self.suggestionsController.moveUp(textView)
                self.moveUp()
//				let string = self.textField.stringValue
//				self.text = string
				return true
			}
			
			if commandSelector == #selector(NSResponder.moveDown(_:)) {
                guard self.editing else {
                    return false
                }
				// Move down in the suggested selections list
//				self.suggestionsController.moveDown(textView)
                self.moveDown()
//				let string = self.textField.stringValue
//				self.text = string
				return true
			}
			
			if commandSelector == #selector(NSResponder.deleteForward(_:)) ||
				commandSelector == #selector(NSResponder.deleteBackward(_:)) {
				/* The user is deleting the highlighted portion of the suggestion or more. Return NO so that the field editor performs the deletion. The field editor will then call -controlTextDidChange:. We don't want to provide a new set of suggestions as that will put back the characters the user just deleted. Instead, set skipNextSuggestion to YES which will cause -controlTextDidChange: to cancel the suggestions window. (see -controlTextDidChange: above)
				*/
                
                self.editing = false
                self.cancel()
				//        self.skipNextSuggestion = YES;
				return false
			}
			
			if commandSelector == #selector(NSResponder.complete(_:)) {
				// The user has pressed the key combination for auto completion. AppKit has a built in auto completion. By overriding this command we prevent AppKit's auto completion and can respond to the user's intention by showing or cancelling our custom suggestions window.
				
				self.editing = false
                self.cancel()
				
				return true
			}
			
			if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let suggestionIndex = self.model.selectedSuggestionIndex,
                   case let .item(item) = self.model.suggestions[suggestionIndex] {
                    self.confirmSuggestion(index: suggestionIndex, item: item)
                }
				
				self.editing = false
				
				return true
			}
			
			if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
				self.editing = false
                self.cancel()
				
				return true
			}
			
			// This is a command that we don't specifically handle, let the field editor do the appropriate thing.
			return false
		}
        
        func windowDidResize(_ notification: Notification) {
            print("window did resize: \(self.window?.frame)")
            self.layoutSuggestions()
        }
	}
}
