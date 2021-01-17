//
//  SuggestionsView.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 12.12.20.
//

import SwiftUI

struct SuggestionView<V: Equatable>: View {
    var suggestion: Suggestion<V>
    @ObservedObject var model: SuggestionsModel<V>
    
    var body: some View {
        let suggestion = self.suggestion
        let model = self.model
        
        return Text(suggestion.text)
            .id(suggestion.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(model.selectedSuggestion == suggestion ? .white : .primary)
            .padding(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(model.selectedSuggestion == suggestion ? Color.accentColor : Color.clear)
            )
            .onHover(perform: { hovering in
                if hovering {
                    model.chooseSuggestion(suggestion)
                } else if model.selectedSuggestion == suggestion {
                    model.chooseSuggestion(nil)
                }
            })
            .onTapGesture {
                model.confirmSuggestion(suggestion)
            }
    }
}

struct SuggestionGroupView<V: Equatable>: View {
    var suggestionGroup: SuggestionGroup<V>
    var showDivider: Bool
    @ObservedObject var model: SuggestionsModel<V>
    
    var body: some View {
        let suggestionGroup = self.suggestionGroup
        let model = self.model
        
        return VStack(alignment: .leading) {
            if self.showDivider {
                Divider()
                    .padding(.top, 7)
            }
            if let title = suggestionGroup.title {
                Text(title)
                    .foregroundColor(.gray)
                    .font(.system(size: 12, weight: .bold))
            }
            VStack(spacing: 0) {
                ForEach(Array(suggestionGroup.suggestions.enumerated()), id: \.0)  { (_, suggestion) in
                    SuggestionView(suggestion: suggestion, model: model)
                }
            }
        }
    }
}

struct SuggestionPopup<V: Equatable>: View {
    @ObservedObject var model: SuggestionsModel<V>
    
    var body: some View {
        let model = self.model
        let suggestionGroups = model.suggestionGroups
        
        return VStack(spacing: 0) {
            ForEach(Array(suggestionGroups.enumerated()), id: \.0)  { (suggestionGroupIndex, suggestionGroup) in
                SuggestionGroupView(suggestionGroup: suggestionGroup, showDivider: suggestionGroupIndex > 0, model: model)
            }
        }
        .padding(10)
    }
}

struct SuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        let suggestion1 = Suggestion(text: "Eight", value: "Eight")
        let suggestion2 = Suggestion(text: "Elder", value: "Elder")
        let group = SuggestionGroup(title: "English", suggestions: [suggestion1, suggestion2])
        let model = SuggestionsModel<String>()
        model.suggestionGroups = [group]
        model.selectedSuggestion = suggestion2
        
        return SuggestionPopup(model: model)
    }
}
