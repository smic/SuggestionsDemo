//
//  SuggestionsView.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 17.09.20.
//

import SwiftUI

struct SuggestionHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
    
    typealias Value = CGFloat
}

struct SuggestionsView: View {
    @ObservedObject var model: SuggestionsModel
//    @State var height: CGFloat = 0
    
    
    var body: some View {
        let model = self.model
        let suggestions = model.suggestions
        print("get suggestions of \(self.model): \(suggestions.count)")
        
//        return GeometryReader { geometry in
            return List(selection: self.$model.selectedSuggestionIndex) {
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
                            .id(item.text)
                            .tag(suggestionIndex)
                                    .background(Color.red)
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
//                    .preference(key: SuggestionHeightPreferenceKey.self, value: geometry.frame(in: .named("Custom")).height)
//                    .log("\(suggestionIndex).row: \(geometry.frame(in: .named("Custom")))")
//                        }
                    )
                }
//                GeometryReader { geometry in
//                    Color.red
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .log("Last: \(geometry.frame(in: .named("Custom")))")
//                }
//            }
            //            .fixedSize(horizontal: false, vertical: true)
//            .log("List: \(geometry.size)")
        }
        //        .environment(\.controlActiveState, .key)
        //        .listStyle(PlainListStyle())
        //        .listStyle(SidebarListStyle())
        //        .fixedSize(horizontal: false, vertical: true)
        //        .frame(height: self.height + 2 * 5)
//            .frame(height: /*CGFloat(suggestions.count * 22 + 2 * 5)*/max(10, self.height))
//        .onPreferenceChange(SuggestionHeightPreferenceKey.self) { height in
//            print("result height: \(height)")
//            self.height = height
//        }
//        .coordinateSpace(name: "SuggestionView")
//        .background(Color.white)
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
        
        return SuggestionsView(model: model)
    }
}
