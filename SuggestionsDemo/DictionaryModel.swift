//
//  Dictionary.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 16.09.20.
//

import Foundation
import Combine

final class DictionaryModel: ObservableObject {
    var englishWords: [String]
    var englishTranslations: [String:String]
    var germanWords: [String]
    var germanTranslations: [String:String]
    
    @Published var currentText: String = ""
    @Published var suggestionGroups: [SuggestionGroup<String>] = []
    @Published var currentTranslation: String?
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        let bundle = Bundle.main
        do {
            let url = bundle.url(forResource: "english_german", withExtension: "json")!
            let data = try! Data(contentsOf: url)
            self.englishTranslations = try! JSONDecoder().decode([String:String].self, from: data)
            self.englishWords = Array(self.englishTranslations.keys)
        }
        do {
            let url = bundle.url(forResource: "german_english", withExtension: "json")!
            let data = try! Data(contentsOf: url)
            self.germanTranslations = try! JSONDecoder().decode([String:String].self, from: data)
            self.germanWords = Array(self.germanTranslations.keys)
        }
        
        self.$currentText
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { text -> [SuggestionGroup<String>] in
                guard !text.isEmpty else {
                    return []
                }
                let englishSuggestions = self.englishWords.lazy.filter({ $0.hasPrefix(text) }).prefix(10).map { word -> Suggestion<String> in
                    Suggestion(text: word, value: word)
                }
                let germanSuggestions = self.germanWords.lazy.filter({ $0.hasPrefix(text) }).prefix(10).map { word -> Suggestion<String> in
                    Suggestion(text: word, value: word)
                }
                var suggestionGroups: [SuggestionGroup<String>] = []
                if !englishSuggestions.isEmpty {
                    suggestionGroups.append(SuggestionGroup<String>(title: "English", suggestions: Array(englishSuggestions)))
                }
                if !germanSuggestions.isEmpty {
                    suggestionGroups.append(SuggestionGroup<String>(title: "German", suggestions: Array(germanSuggestions)))
                }
                return suggestionGroups
            }
            .assign(to: \DictionaryModel.suggestionGroups, on: self)
            .store(in: &cancellables)
        
        self.$currentText
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { text -> String? in
                if let englishTranslation = self.englishTranslations[text] {
                    return englishTranslation
                }
                if let germanTranslation = self.germanTranslations[text] {
                    return germanTranslation
                }
                return nil
            }
            .assign(to: \DictionaryModel.currentTranslation, on: self)
            .store(in: &cancellables)
    }
}
