//
//  SMSuggestionsWindowController.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 16.09.20.
//

import AppKit

enum SMSuggestion {
    case item(SMSuggestionItem)
    case group(SMSuggestionGroup)
}

struct SMSuggestionItem {
    var title: String = ""
    var attributedTitle: NSAttributedString?
    var attributedSelectedTitle: NSAttributedString?
    var text: String = ""
    var representedObject: Any?
}

struct SMSuggestionGroup {
    var title: String = ""
    var attributedTitle: NSAttributedString?
}


final class SMSuggestionsWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    
    private var tableView: NSTableView?
    
    private let suggestionColumnIdentifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "Suggestions")
    private let itemViewIdentifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "Item")
    private let groupViewIdentifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "Group")
    
    private var previouslySelectedRow: Int = -1
    
    init() {
        
        let contentRect = NSRect(x: 0, y: 0, width: 20, height: 20);
        let window = NSWindow(contentRect: contentRect, styleMask: .borderless, backing: .buffered, defer: true)
        window.hasShadow = true
        window.backgroundColor = .clear
        window.isOpaque = false
        
        super.init(window: window)
        
        window.delegate = self

        // SuggestionsWindow is a transparent window, create RoundedCornersView and set it as the content view to draw a menu like window.
        let contentView = NSVisualEffectView(frame: contentRect)
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
        tableView.target = self
        tableView.action = #selector(selectTableRow(_:))
        tableView.autoresizingMask = [.width, .maxYMargin]
        
        let bundle = Bundle(for: SMSuggestionsWindowController.self)
        tableView.register(NSNib(nibNamed: "SMSuggestionItemView", bundle: bundle), forIdentifier: self.itemViewIdentifier)
        tableView.register(NSNib(nibNamed: "SMSuggestionGroupView", bundle: bundle), forIdentifier: self.groupViewIdentifier)
        
        let column = NSTableColumn(identifier: self.suggestionColumnIdentifier)
        column.isEditable = true
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        
        scrollView.documentView = tableView
        self.tableView = tableView
        
        let trackingArea = NSTrackingArea(rect: .zero, options: [.inVisibleRect, .mouseEnteredAndExited, .mouseMoved, .activeInActiveApp], owner: self, userInfo: nil)
        contentView.addTrackingArea(trackingArea)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let tableView = self.tableView {
            tableView.delegate = nil
            tableView.dataSource = nil
        }
    }
    
    public var onSelectSuggestionItem: ((SMSuggestionItem?) -> Void)?
    
    private var parentTextField: NSTextField?
    private var localMouseDownEventMonitor: Any?
    private var lostFocusObserver: Any?

    /* Position and lay out the suggestions window, set up auto cancelling tracking, and wires up the logical relationship for accessibility.
    */
    public func begin(for parentTextField: NSTextField) {
        guard let suggestionWindow = self.window,
              let parentWindow = parentTextField.window else {
            return
        }
        let parentFrame = parentTextField.frame
        var frame = suggestionWindow.frame
        frame.size.width = parentFrame.size.width;
        
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
        
        suggestionWindow.setFrame(frame, display: false)
        suggestionWindow.setFrameTopLeftPoint(location)
        self.layoutSuggestions() // The height of the window will be adjusted in -layoutSuggestions.
        
        // add the suggestion window as a child window so that it plays nice with Expose
        parentWindow.addChildWindow(suggestionWindow, ordered: .above)
        
        // keep track of the parent text field in case we need to commit or abort editing.
        self.parentTextField = parentTextField
        
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

    /* Order out the suggestion window, disconnect the accessibility logical relationship and dismantle any observers for auto cancel.
        Note: It is safe to call this method even if the suggestions window is not currently visible.
    */
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
        
        self.tableView?.deselectAll(nil)
    }

    /* Update the array of suggestions.
    */
    public var suggestions: [SMSuggestion] = [] {
        didSet {
            // We only need to update the layout if the window is currently visible.
            if self.window?.isVisible == true {
                self.layoutSuggestions()
            }
        }
    }

    /* Returns the dictionary of the currently selected suggestion.
    */
    var selectedSuggestion: SMSuggestionItem? {
        guard let tableView = self.tableView else {
            return nil
        }
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 else {
            return nil
        }
        let suggestion = self.suggestions[selectedRow];
        switch suggestion {
        case let .item(item):
            return item
        default:
            return nil
        }
    }

    // Creates suggestion views from suggestionprototype.xib for every suggestion and resize the suggestion window accordingly. Also creates a thumbnail image on a backgroung aue.
    private func layoutSuggestions() {
        guard let window = self.window,
              let tableView = self.tableView else {
            return
        }

        tableView.reloadData()
        
        // We have added all of the suggestion to the window. Now set the size of the window.
        
        // Don't forget to account for the extra room needed the rounded corners.
    //    NSUInteger numberOfSuggestions = self.suggestions.count;
        var contentHeight: CGFloat = /*numberOfSuggestions * tableView.rowHeight + numberOfSuggestions * tableView.intercellSpacing.height + */ 2 * 5
        for rowIndex in 0..<self.numberOfRows(in: tableView) {
            contentHeight += self.tableView(tableView, heightOfRow:rowIndex)
            contentHeight += tableView.intercellSpacing.height;
        }
        
        var winFrame = window.frame
        winFrame.origin.y = winFrame.maxY - contentHeight
        winFrame.size.height = contentHeight;
        window.setFrame(winFrame, display: true)
    }

    internal func isGroup(at row: NSInteger) -> Bool {
        let suggestions = self.suggestions
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

    internal var firstItemRow: Int? {
        let suggestions = self.suggestions
        guard !suggestions.isEmpty else {
            return nil
        }
        
        for (currentRow, suggestion) in suggestions.enumerated() {
            if case .group(_) = suggestion {
                return currentRow
            }
        }
        return 1;
    }

    internal func nextItemRow(for row: Int) -> Int? {
        let suggestions = self.suggestions
        guard 0 <= row || row < suggestions.count else {
            return nil
        }
        
        for (currentRow, suggestion) in suggestions.enumerated() {
            print("test current row: \(currentRow)")
            guard currentRow > row else {
                print("skip")
                continue
            }
            if case .item(_) = suggestion {
                print("found: \(row)")
                return currentRow
            }
        }
        return nil
    }

    internal func previousItemRow(for row: Int) -> Int? {
        let suggestions = self.suggestions
        guard 0 <= row || row < suggestions.count else {
            return nil
        }
        
        for (currentRow, suggestion) in suggestions.enumerated().reversed() {
            guard currentRow < row else {
                continue
            }
            if case .item(_) = suggestion {
                return currentRow
            }
        }
        return nil
    }

    // MARK: - Actions

    @IBAction func selectTableRow(_ sender: Any?) {
        guard let tableView = self.tableView else {
            return
        }
        let selectedRow = tableView.clickedRow
        guard selectedRow >= 0 else {
            NSSound.beep()
            return
        }
        
        guard let parentTextField = self.parentTextField else {
            return;
        }
        parentTextField.validateEditing()
        parentTextField.abortEditing()
        parentTextField.sendAction(parentTextField.action, to:parentTextField.target)
        self.cancel()
    }

    // MARK: - Mouse Handling

    /* The mouse has left one of our child image views. Set the selection to no selection and send action
    */
    internal override func mouseExited(with event: NSEvent) {
        guard let suggestionWindow = self.window else {
            return
        }
        if suggestionWindow.isVisible {
            self.tableView?.deselectAll(nil)
        }
    }

    internal override func mouseMoved(with event: NSEvent) {
        guard let tableView = self.tableView else {
            return
        }
        let location = tableView.convert(event.locationInWindow, from: nil)
        guard tableView.visibleRect.contains(location) else {
            return
        }
        let row = tableView.row(at: location)
        guard row >= 0 else {
            if tableView.selectedRow >= 0 {
                tableView.deselectAll(nil)
            }
            return
        }
        guard !self.isGroup(at: row) else {
            return
        }
        if tableView.selectedRow != row {
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }

    /* The user released the mouse button. Force the parent text field to send its return action. Notice that there is no mouseDown: implementation. That is because the user may hold the mouse down and drag into another view.
    */
    internal override func mouseUp(with event: NSEvent) {
        guard let parentTextField = self.parentTextField else {
            return
        }
        parentTextField.validateEditing()
        parentTextField.abortEditing()
        parentTextField.sendAction(parentTextField.action, to:parentTextField.target)
        self.cancel()
    }

    // MARK: - Keyboard Tracking

    /* In addition to tracking the mouse, we want to allow changing our selection via the keyboard. However, the suggestion window never gets key focus as the key focus remains on te text field. Therefore we need to route move up and move down action commands from the text field and this controller. See CustomMenuAppDelegate.m -control:textView:doCommandBySelector: to see how that is done.
    */

    /* move the selection up and send action.
    */
    internal override func moveUp(_ sender: Any?) {
        guard let tableView = self.tableView else {
            return
        }
        let selectedRow = tableView.selectedRow
        
        guard selectedRow >= 0 else {
            return
        }

        guard let previousItemRow = self.previousItemRow(for: selectedRow) else {
            tableView.deselectAll(nil)
            return
        }
        tableView.selectRowIndexes(IndexSet(integer: previousItemRow), byExtendingSelection: false)
    }

    /* move the selection down and send action.
    */
    internal override func moveDown(_ sender: Any?) {
        guard let tableView = self.tableView else {
            return
        }
        let selectedRow = tableView.selectedRow;
        
        print("selectedRow: \(selectedRow)")
        guard selectedRow >= 0 else {
            guard let firstItemRow = self.firstItemRow else {
                return
            }
            tableView.selectRowIndexes(IndexSet(integer: firstItemRow), byExtendingSelection: false)
            return
        }
        
        guard let nextItemRow = self.nextItemRow(for: selectedRow) else {
            print("skip")
            return
        }
        print("nextItemRow: \(nextItemRow)")
        tableView.selectRowIndexes(IndexSet(integer: nextItemRow), byExtendingSelection: false)
    }

    // MARK: - Table View Data Source

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.suggestions.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let suggestions = self.suggestions
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
    }

    // MARK - Table View Delegate

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
        guard let onSelectSuggestionItem = self.onSelectSuggestionItem else {
            return
        }
        if selectedRow < 0 {
            if suggestionWindow.isVisible {
                onSelectSuggestionItem(nil)
            }
            return
        }
        switch self.suggestions[selectedRow] {
        case let .item(item):
            if suggestionWindow.isVisible {
                onSelectSuggestionItem(item)
            }
        default:
            if suggestionWindow.isVisible {
                onSelectSuggestionItem(nil)
            }
        }
        self.previouslySelectedRow = selectedRow
    }
}
