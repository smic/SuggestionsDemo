//
//  SuggestionsView.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 12.12.20.
//

import SwiftUI

struct SuggestionsView: View {
    @Binding var text: String
    @ObservedObject var model: SuggestionsModel
    
    var body: some View {
        let model = self.model
        let suggestions = model.suggestions
        
        return VStack(spacing: 0) {
            ForEach(suggestions.indices, id: \.self)  { suggestionIndex in
                return Group {
                    switch suggestions[suggestionIndex] {
                    case let .item(item):
                        Text(item.title)
                            .id(item.text)
                            .tag(suggestionIndex)
                    case let .group(group):
                        VStack(alignment: .leading) {
                            Divider()
                            Text(group.title)
                                .foregroundColor(.gray)
                                .font(.caption)
                                .bold()
                        }
                        .tag(suggestionIndex)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(model.selectedSuggestionIndex == suggestionIndex ? .white : .black)
                .padding(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(model.selectedSuggestionIndex == suggestionIndex ? Color.accentColor : Color.clear)
                )
                .onHover(perform: { hovering in
                    if case let .item(item) = suggestions[suggestionIndex] {
                        if hovering {
                            model.chooseSuggestion(index: suggestionIndex, item: item)
                        } else if model.selectedSuggestionIndex == suggestionIndex {
                            model.chooseSuggestion(index: nil, item: nil)
                        }
                    }
                })
                .onTapGesture {
                    if case let .item(item) = suggestions[suggestionIndex] {
                        model.confirmSuggestion(index: suggestionIndex, item: item, binding: self.$text)
                    }
                }
            }
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        let model = SuggestionsModel()
        do {
            var group = SMSuggestionGroup()
            group.title = "English"
            model.suggestions.append(.group(group))
        }
        do {
            var item = SMSuggestionItem()
            item.title = "Eight"
            model.suggestions.append(.item(item))
        }
        do {
            var item = SMSuggestionItem()
            item.title = "Elder"
            model.suggestions.append(.item(item))
        }
        model.selectedSuggestionIndex = 1
        
        return SuggestionsView(text: .constant(""), model: model)
    }
}
