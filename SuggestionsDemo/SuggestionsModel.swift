//
//  SuggestionsModel.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 12.12.20.
//

import Foundation

final class SuggestionsModel: ObservableObject {
    @Published var suggestions: [SMSuggestion] = []
    @Published var selectedSuggestionIndex: Int?
    
    var onChoose: ((Int?, SMSuggestionItem?) -> Void)?
    var onConfirm: ((Int, SMSuggestionItem) -> Void)?
}
