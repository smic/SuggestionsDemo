//
//  SuggestionsView.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 17.09.20.
//

import SwiftUI

struct SuggestionsView: View {
    final class Model: ObservableObject {
        @Published var suggestions: [SMSuggestion] = []
        @Published var selectedSuggestionIndex: Int?
        
        var onChoose: ((Int?, SMSuggestionItem?) -> Void)?
        var onConfirm: ((Int, SMSuggestionItem) -> Void)?
    }
    
    @ObservedObject var model: Model
    
    
    var body: some View {
        let model = self.model
        let suggestions = model.suggestions
//        print("get suggestions of \(self.model): \(suggestions)")
        
        return List(suggestions.indices, id: \.self, selection: self.$model.selectedSuggestionIndex) { suggestionIndex -> AnyView in
            let suggestion = suggestions[suggestionIndex]
//            print("suggestionIndex: \(suggestionIndex) suggestion: \(suggestion)")
            return AnyView(Group {
                switch suggestion {
                case let .item(item):
                    ZStack {
                        Text(item.title)
                        DebugView { view in
                            for superview in sequence(first: view, next: { $0.superview }) {
                                if let rowView = superview as? NSTableRowView {
                                    print("row \"\(item.title)\" emphasized: \(rowView.isEmphasized)")
                                    rowView.isEmphasized = true
                                    break
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                    .onHover(perform: { hovering in
                        if hovering {
                            model.selectedSuggestionIndex = suggestionIndex
                            self.model.onChoose?(suggestionIndex, item)
                        } else if model.selectedSuggestionIndex == suggestionIndex {
                            model.selectedSuggestionIndex = nil
                            self.model.onChoose?(nil, nil)
                        }
                    })
                    .onTapGesture {
                        model.onConfirm?(suggestionIndex, item)
                    }
                    .background(Color.red)
                    .tag(suggestionIndex)
                case let .group(group):
                    VStack(alignment: .leading) {
                        Divider()
                        Text(group.title)
                            .foregroundColor(.gray)
                            .font(.caption)
                            .bold()
                    }
                    .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                    .tag(suggestionIndex)
                }
            })
        }
        .environment(\.controlActiveState, .key)
//        .listStyle(PlainListStyle())
//        .listStyle(SidebarListStyle())
        .frame(height: CGFloat(self.model.suggestions.count * 20))
        .background(Color.red)
    }
}

struct SuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        let model = SuggestionsView.Model()
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
        
        return SuggestionsView(model: model)
    }
}
