//
//  SuggestionsModel.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 12.12.20.
//

import Foundation
import SwiftUI

final class SuggestionsModel: ObservableObject {
    @Published var suggestions: [SMSuggestion] = []
    @Published var selectedSuggestionIndex: Int?
    
    @Published var suggestionsVisible: Bool = false

    @Published var suggestionConfirmed: Bool = false
    
    @Published var width: CGFloat = 100
    
    internal func modifiedText(text: String, binding: Binding<String>) {
        binding.wrappedValue = text
        
        self.selectedSuggestionIndex = nil
        self.suggestionsVisible = true
        self.suggestionConfirmed = false
    }
    
    internal func cancel() {
        self.suggestionConfirmed = false
        self.suggestionsVisible = false
        
        self.selectedSuggestionIndex = nil
    }
    
    internal func moveUp() {
        self.suggestionConfirmed = false
        
        guard let selectedRow = self.selectedSuggestionIndex else {
            return
        }

        guard let (index, item) = self.previousItemRow(for: selectedRow) else {
            self.selectedSuggestionIndex = nil
            return
        }
        self.selectedSuggestionIndex = index
    }

    internal func moveDown() {
        self.suggestionConfirmed = false
        
        guard let selectedIndex = self.selectedSuggestionIndex else {
            guard let (index, item) = self.firstItem else {
                return
            }
            self.selectedSuggestionIndex = index
            return
        }
        
        guard let (index, item) = self.nextItem(for: selectedIndex) else {
            return
        }
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
    }
    
    internal func confirmSuggestion(index: Int, item: SMSuggestionItem, binding: Binding<String>) {
        
        self.selectedSuggestionIndex = index
        self.suggestionsVisible = false

        binding.wrappedValue = item.text
        
        self.suggestionConfirmed = true
    }
}
