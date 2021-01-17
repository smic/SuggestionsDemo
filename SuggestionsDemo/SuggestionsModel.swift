//
//  SuggestionsModel.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 12.12.20.
//

import Foundation
import SwiftUI

internal final class SuggestionsModel<V: Equatable>: ObservableObject {
    @Published var suggestionGroups: [SMSuggestionGroup<V>] = []
    @Published var selectedSuggestion: SMSuggestion<V>?
    
    @Published var suggestionsVisible: Bool = false

    @Published var suggestionConfirmed: Bool = false
    
    @Published var width: CGFloat = 100
    
    var textBinding: Binding<String>?
    
    internal func modifiedText(_ text: String) {
        self.textBinding?.wrappedValue = text
        
        self.selectedSuggestion = nil
        self.suggestionsVisible = text.isEmpty ? false : true
        self.suggestionConfirmed = false
    }
    
    internal func cancel() {
        self.suggestionConfirmed = false
        self.suggestionsVisible = false
        
        self.selectedSuggestion = nil
    }
    
    private var suggestions: [SMSuggestion<V>] {
        self.suggestionGroups.flatMap(\.suggestions)
    }
    
    internal func moveUp() {
        self.suggestionConfirmed = false
        
        guard let selectedSuggestion = self.selectedSuggestion else {
            return
        }

        guard let suggestion = self.previousSuggestion(for: selectedSuggestion) else {
            self.selectedSuggestion = nil
            return
        }
        self.selectedSuggestion = suggestion
    }

    internal func moveDown() {
        self.suggestionConfirmed = false
        
        guard let selectedSuggestion = self.selectedSuggestion else {
            guard let suggestion = self.firstSuggestion else {
                return
            }
            self.selectedSuggestion = suggestion
            return
        }
        
        guard let suggestion = self.nextSuggestion(for: selectedSuggestion) else {
            return
        }
        self.selectedSuggestion = suggestion
    }
    
    internal var firstSuggestion: SMSuggestion<V>? {
        let suggestions = self.suggestions
        return suggestions.first
    }

    internal func nextSuggestion(for suggestion: SMSuggestion<V>) -> SMSuggestion<V>? {
        let suggestions = self.suggestions
        guard let index = suggestions.firstIndex(of: suggestion),
              index + 1 < suggestions.count else {
            return nil
        }
        return suggestions[index + 1]
    }

    internal func previousSuggestion(for suggestion: SMSuggestion<V>) -> SMSuggestion<V>? {
        let suggestions = self.suggestions
        guard let index = suggestions.firstIndex(of: suggestion),
              index - 1 >= 0 else {
            return nil
        }
        return suggestions[index - 1]
    }
    
    internal func chooseSuggestion(_ suggestion: SMSuggestion<V>?) {
        self.selectedSuggestion = suggestion
        self.suggestionConfirmed = false
    }
    
    internal func confirmSuggestion(_ suggestion: SMSuggestion<V>) {
        
        self.selectedSuggestion = suggestion
        self.suggestionsVisible = false

        self.textBinding?.wrappedValue = suggestion.text
        
        self.suggestionConfirmed = true
    }
}
