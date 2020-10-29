//
//  SMSuggestionTextField.swift
//  PubChemDemo
//
//  Created by Stephan Michels on 27.08.20.
//  Copyright © 2020 Stephan Michels. All rights reserved.
//

import AppKit
import SwiftUI

// original code from https://developer.apple.com/library/archive/samplecode/CustomMenus

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
    
    class MyWindow: NSWindow {
//        @objc var hasKeyAppearance: Bool {
//            return true
//        }
        
        override var isMainWindow: Bool {
            return true
        }
        
        override var isKeyWindow: Bool {
//            return NSApp.isActive ? true : super.isKeyWindow
            return true
        }
    }
    
	class Coordinator: NSObject, NSTextFieldDelegate, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
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
        
        private let suggestionColumnIdentifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "Suggestions")
        private let itemViewIdentifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "Item")
        private let groupViewIdentifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "Group")
        
        private var tableView: NSTableView?
		
		init(text: Binding<String>) {
			self._text = text
            
            let contentRect = NSRect(x: 0, y: 0, width: 20, height: 20);
            let window = MyWindow(contentRect: contentRect, styleMask: .borderless, backing: .buffered, defer: true)
            window.hasShadow = true
            window.backgroundColor = .clear
            window.isOpaque = false
            self.window = window
            
            let hostingController = NSHostingController(rootView: AnyView(SuggestionsView(model: self.model)))
            window.contentViewController = hostingController
            self.hostingController = hostingController
            
            super.init()
            
            window.delegate = self
            
            // SuggestionsWindow is a transparent window, create RoundedCornersView and set it as the content view to draw a menu like window.
            /*let contentView = NSVisualEffectView(frame: contentRect)
            contentView.material = .popover
            contentView.blendingMode = .behindWindow
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 5.0
            contentView.layer?.masksToBounds = true
            window.contentView = contentView
            
            let scrollViewFrame = contentView.bounds
            let scrollView = NSScrollView(frame: scrollViewFrame)
            scrollView.borderType = .noBorder
            scrollView.focusRingType = .none
            scrollView.drawsBackground = false
            scrollView.hasVerticalScroller = false
            scrollView.hasHorizontalScroller = false
            scrollView.autoresizesSubviews = true
            scrollView.autoresizingMask = [.width, .height]
            contentView.addSubview(scrollView)
            
            let tableView = NSTableView(frame: scrollView.contentView.bounds)
            tableView.rowHeight = 19.0
            tableView.intercellSpacing = .zero
            tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
            tableView.focusRingType = .none
            tableView.allowsColumnReordering = false
            tableView.allowsColumnResizing = false
            tableView.allowsMultipleSelection = false
            tableView.allowsEmptySelection = true
            tableView.allowsColumnSelection = false
            tableView.headerView = nil;
            tableView.selectionHighlightStyle = .regular
            tableView.backgroundColor = .clear
            tableView.delegate = self
            tableView.dataSource = self
//            tableView.target = self
//            tableView.action = #selector(selectTableRow(_:))
            tableView.autoresizingMask = [.width, .maxYMargin]
            
//            let bundle = Bundle(for: SMSuggestionsWindowController.self)
//            tableView.register(NSNib(nibNamed: "SMSuggestionItemView", bundle: bundle), forIdentifier: self.itemViewIdentifier)
//            tableView.register(NSNib(nibNamed: "SMSuggestionGroupView", bundle: bundle), forIdentifier: self.groupViewIdentifier)
            
            let column = NSTableColumn(identifier: self.suggestionColumnIdentifier)
            column.isEditable = true
            column.resizingMask = .autoresizingMask
            tableView.addTableColumn(column)
            
            scrollView.documentView = tableView
            self.tableView = tableView*/
            
            self.model.onChoose = { [weak self] (suggestionIndex, suggestionItem) in
                self?.chooseSuggestion(index: suggestionIndex, item: suggestionItem)
            }
            self.model.onConfirm = { [weak self] (suggestionIndex, suggestionItem) in
                self?.confirmSuggestion(index: suggestionIndex, item: suggestionItem)
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
            
//            self.tableView?.reloadData()
            
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
            
//            self.tableView?.reloadData()
            
            print("1.suggestionWindow.frame: \(suggestionWindow.frame)")
            
//            suggestionWindow.setFrame(frame, display: false)
//            suggestionWindow.setFrameTopLeftPoint(location)
//            print("2.suggestionWindow.frame: \(suggestionWindow.frame)")

            // We have added all of the suggestion to the window. Now set the size of the window.
            
//            print("preferredContentSize: \(self.hostingController.preferredContentSize)")
//            print("intrinsicContentSize: \(self.hostingController.view.intrinsicContentSize)")
            
//            self.hostingController.view.layoutSubtreeIfNeeded()
            let availableSize = CGSize(width: self.textField.frame.size.width, height: 500)
            print("availableSize: \(availableSize)")
            let contentSize = self.hostingController.sizeThatFits(in: availableSize)
//            let contentSize = self.tableView?.frame.size ?? .zero
            print("contentSize: \(contentSize)")
            
//            let contentSize = CGSize(width: self.textField.frame.size.width, height: CGFloat(self.model.suggestions.count * 20))
            
            // Don't forget to account for the extra room needed the rounded corners.
        //    NSUInteger numberOfSuggestions = self.suggestions.count;
//            var contentHeight: CGFloat = /*numberOfSuggestions * tableView.rowHeight + numberOfSuggestions * tableView.intercellSpacing.height + */ 2 * 5
            /*for rowIndex in 0..<self.numberOfRows(in: tableView) {
                contentHeight += self.tableView(tableView, heightOfRow:rowIndex)
                contentHeight += tableView.intercellSpacing.height;
            }*/
            
            var winFrame = CGRect(x: location.x,
                                  y: location.y - contentSize.height,
                                  width: availableSize.width,
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
            guard let index = index,
                  let item = item else {
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
            
            self.tableView?.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
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
        
        func controlTextDidEndEditing(_ obj: Notification) {
            /* If the suggestionController is already in a cancelled state, this call does nothing and is therefore always safe to call.
            */
            self.cancel()
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
        
        // MARK: - Table View Data Source

        func numberOfRows(in tableView: NSTableView) -> Int {
            return self.model.suggestions.count
        }

        /*func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
            let suggestions = self.model.suggestions
            switch suggestions[row] {
            case let .item(item):
                if row == tableView.selectedRow,
                    let attributedSelectedTitle = item.attributedSelectedTitle {
                    return attributedSelectedTitle
                }
                if let attributedTitle = item.attributedTitle {
                    return attributedTitle
                }
                return item.title
            case let .group(group):
                if let attributedTitle = group.attributedTitle {
                    return attributedTitle
                }
                return group.title
            }
        }*/
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let suggestionIndex = row
            let model = self.model
            let suggestion = model.suggestions[suggestionIndex]
            switch suggestion {
            case let .item(item):
                return NSHostingView(rootView: AnyView(
                                        Text(item.title)
                                            .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                                            .onHover(perform: { hovering in
                                                if hovering {
                                                    model.selectedSuggestionIndex = suggestionIndex
                                                    self.model.onChoose?(suggestionIndex, item)
                                                } else if model.selectedSuggestionIndex == suggestionIndex {
                                                    model.selectedSuggestionIndex = nil
                                                    self.model.onChoose?(nil, nil)
                                                }
                                            })
                                            .onTapGesture {
                                                model.onConfirm?(suggestionIndex, item)
                                            }
                ))
            case let .group(group):
                return NSHostingView(rootView: AnyView(
                    VStack(alignment: .leading) {
                        Divider()
                        Text(group.title)
                            .foregroundColor(.gray)
                            .font(.caption)
                            .bold()
                    }
                    .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                ))
            }
        }

        // MARK - Table View Delegate
        
        /*private var previouslySelectedRow: Int = -1
        
        internal func isGroup(at row: NSInteger) -> Bool {
            let suggestions = self.model.suggestions
            guard 0 <= row || row < suggestions.count else {
                return false
            }
            switch suggestions[row] {
            case .group(_):
                return true
            default:
                return false
            }
        }

        func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
            if self.isGroup(at: row) {
                return row == 0 ? 31 - 13 : 31;
            }
            return 19 + 1;
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            if self.isGroup(at: row) {
                return tableView.makeView(withIdentifier: self.groupViewIdentifier, owner: self)
            }
            return tableView.makeView(withIdentifier: self.itemViewIdentifier, owner: self)
        }
        
        func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
            return IndexSet(proposedSelectionIndexes.filter({ !self.isGroup(at: $0) }))
        }

        func tableViewSelectionDidChange(_ notification: Notification) {
            guard let tableView = self.tableView else {
                return
            }
            let selectedRow = tableView.selectedRow
            var rowIndexesToReload = IndexSet()
            if selectedRow >= 0 {
                rowIndexesToReload.insert(selectedRow)
            }
            let previouslySelectedRow = self.previouslySelectedRow
            if previouslySelectedRow >= 0 {
                rowIndexesToReload.insert(previouslySelectedRow)
            }
            tableView.reloadData(forRowIndexes: rowIndexesToReload, columnIndexes: IndexSet(integer: 0))
            guard let suggestionWindow = self.window else {
                return
            }
//            guard let onSelectSuggestionItem = self.onSelectSuggestionItem else {
//                return
//            }
//            if selectedRow < 0 {
//                if suggestionWindow.isVisible {
//                    onSelectSuggestionItem(nil)
//                }
//                return
//            }
//            switch self.model.suggestions[selectedRow] {
//            case let .item(item):
//                if suggestionWindow.isVisible {
//                    onSelectSuggestionItem(item)
//                }
//            default:
//                if suggestionWindow.isVisible {
//                    onSelectSuggestionItem(nil)
//                }
//            }
//            self.previouslySelectedRow = selectedRow
        }*/
	}
}
