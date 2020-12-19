//
//  SuggestionsModel.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 12.12.20.
//

import Foundation
import AppKit
import SwiftUI

final class SuggestionsModel: ObservableObject {
    @Published var suggestions: [SMSuggestion] = []
    @Published var selectedSuggestionIndex: Int?
//    var selectedSuggestionIndex: Int? {
//        didSet {
//            if self.selectedSuggestionIndex != nil {
//                print("break")
//            }
//        }
//    }
    
    @Published var suggestionsVisible: Bool = false
    /*var suggestionsVisible: Bool = false {
        didSet {
            print("set suggestionsVisible: \(self.suggestionsVisible)")
            print("Thread: \(Thread.callStackSymbols)")
        }
    }*/
    @Published var textEdited: Bool = false
    @Published var suggestionConfirmed: Bool = false
    
    var window: NSWindow?
    
    var onChoose: ((Int?, SMSuggestionItem?) -> Void)?
    var onConfirm: ((Int, SMSuggestionItem) -> Void)?
    
//    internal func showSuggestions() {
//        self.suggestionsVisible = true
//    }
    
    internal func modifiedText(text: String, binding: Binding<String>) {
        binding.wrappedValue = text
        self.textEdited = true
        
        self.selectedSuggestionIndex = nil
        self.suggestionsVisible = true
        self.suggestionConfirmed = false
    }
    
    internal func cancel() {
        self.textEdited = false
        self.suggestionConfirmed = false
        self.suggestionsVisible = false
        
        self.selectedSuggestionIndex = nil
    }
    
    internal func delete(text: String, binding: Binding<String>) {
        binding.wrappedValue = text
        self.textEdited = true
        
        self.selectedSuggestionIndex = nil
        self.suggestionsVisible = false
    }
    
    internal func changeSelection() {
        self.suggestionConfirmed = false
    }
    
    internal func moveUp() {
        self.suggestionConfirmed = false
        
        guard let selectedRow = self.selectedSuggestionIndex else {
            return
        }

        guard let (index, item) = self.previousItemRow(for: selectedRow) else {
            self.selectedSuggestionIndex = nil
//                self.chooseSuggestion(index: nil, item: nil)
            return
        }
//            self.chooseSuggestion(index: index, item: item)
        self.selectedSuggestionIndex = index
    }

    internal func moveDown() {
        self.suggestionConfirmed = false
        
        guard let selectedIndex = self.selectedSuggestionIndex else {
            guard let (index, item) = self.firstItem else {
                return
            }
//                self.chooseSuggestion(index: index, item: item)
            self.selectedSuggestionIndex = index
            return
        }
        
        guard let (index, item) = self.nextItem(for: selectedIndex) else {
            return
        }
//            self.chooseSuggestion(index: index, item: item)
        self.selectedSuggestionIndex = index
    }
    
    internal var firstItem: (Int, SMSuggestionItem)? {
        let suggestions = self.suggestions
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

    internal func nextItem(for index: Int) -> (Int, SMSuggestionItem)? {
        let suggestions = self.suggestions
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

    internal func previousItemRow(for index: Int) -> (Int, SMSuggestionItem)? {
        let suggestions = self.suggestions
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
    
    internal func chooseSuggestion(index: Int?, item: SMSuggestionItem?) {
        self.selectedSuggestionIndex = index
        self.suggestionConfirmed = false
        self.onChoose?(index, item)
    }
    
    internal func confirmSuggestion(index: Int, item: SMSuggestionItem, binding: Binding<String>) {
        
//        self.cancel()
        self.selectedSuggestionIndex = index
        self.suggestionsVisible = false

        binding.wrappedValue = item.text
        
        self.suggestionConfirmed = true
        
//        self.text = item.text
//        model.suggestionConfirmed = true
//        model.selectedSuggestionIndex = nil
//        model.suggestionsVisible = false
        self.onConfirm?(index, item)
    }
}