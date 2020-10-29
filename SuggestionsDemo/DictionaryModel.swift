//
//  Dictionary.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 16.09.20.
//

import Foundation
import Combine

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


final class DictionaryModel: ObservableObject {
    var englishWords: [String]
    var englishTranslations: [String:String]
    var germanWords: [String]
    var germanTranslations: [String:String]
    
    @Published var currentText: String = ""
    @Published var suggestions: [SMSuggestion] = []
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
            .map { text -> [SMSuggestion] in
                guard !text.isEmpty else {
                    return []
                }
                let englishSuggestionItems = self.englishWords.lazy.filter({ $0.hasPrefix(text) }).prefix(10).map { word -> SMSuggestion in
                    var item = SMSuggestionItem()
                    item.title = word
                    item.text = word
                    return .item(item)
                }
                let germanSuggestionItems = self.germanWords.lazy.filter({ $0.hasPrefix(text) }).prefix(10).map { word -> SMSuggestion in
                    var item = SMSuggestionItem()
                    item.title = word
                    item.text = word
                    return .item(item)
                }
                var suggestions: [SMSuggestion] = []
                if !englishSuggestionItems.isEmpty {
                    var group = SMSuggestionGroup()
                    group.title = "English"
                    suggestions.append(.group(group))
                    suggestions.append(contentsOf: englishSuggestionItems)
                }
                if !germanSuggestionItems.isEmpty {
                    var group = SMSuggestionGroup()
                    group.title = "German"
                    suggestions.append(.group(group))
                    suggestions.append(contentsOf: germanSuggestionItems)
                }
                return suggestions
            }
            .assign(to: \DictionaryModel.suggestions, on: self)
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
