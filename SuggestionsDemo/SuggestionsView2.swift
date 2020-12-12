//
//  SuggestionsView2.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 12.12.20.
//

import SwiftUI

struct SuggestionsView2: View {
    @ObservedObject var model: SuggestionsModel
    
    var body: some View {
        let model = self.model
        let suggestions = model.suggestions
        print("get suggestions of \(self.model): \(suggestions.count)")
        
        return VStack(spacing: 0) {
            ForEach(suggestions.indices, id: \.self)  { suggestionIndex -> AnyView in
                //            return List(suggestions.indices, id: \.self, selection: self.$model.selectedSuggestionIndex) { suggestionIndex -> AnyView in
                let suggestion = suggestions[suggestionIndex]
                //            print("suggestionIndex: \(suggestionIndex) suggestion: \(suggestion)")
                return AnyView(
                    //                        GeometryReader { geometry in
                    Group {
                        switch suggestion {
                        case let .item(item):
                            //                            ForceEmphasizedView {
                            Text(item.title)
                                //                            }
                                //                            .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                                .id(item.text)
                                .tag(suggestionIndex)
                        case let .group(group):
                            //                            ForceEmphasizedView {
                            VStack(alignment: .leading) {
                                Divider()
                                Text(group.title)
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                    .bold()
                            }
                            //                            }
                            //                            .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
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
                        if case let .item(item) = suggestion {
                            if hovering {
                                model.selectedSuggestionIndex = suggestionIndex
                                self.model.onChoose?(suggestionIndex, item)
                            } else if model.selectedSuggestionIndex == suggestionIndex {
                                model.selectedSuggestionIndex = nil
                                self.model.onChoose?(nil, nil)
                            }
                        }
                    })
                    .onTapGesture {
                        if case let .item(item) = suggestion {
                            model.onConfirm?(suggestionIndex, item)
                        }
                    }
                    //                    .preference(key: SuggestionHeightPreferenceKey.self, value: geometry.frame(in: .named("Custom")).height)
                    //                    .log("\(suggestionIndex).row: \(geometry.frame(in: .named("Custom")))")
                    //                        }
                )
            }
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SuggestionsView2_Previews: PreviewProvider {
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
        
        return SuggestionsView2(model: model)
    }
}
