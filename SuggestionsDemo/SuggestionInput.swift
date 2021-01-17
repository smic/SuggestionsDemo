//
//  SuggestionInput.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 13.12.20.
//

import SwiftUI

struct SMSuggestion<V: Equatable>: Equatable {
    var text: String = ""
    var value: V
    
    static func ==(_ lhs: SMSuggestion<V>, _ rhs: SMSuggestion<V>) -> Bool {
        return lhs.value == rhs.value
    }
}

struct SMSuggestionGroup<V: Equatable>: Equatable {
    var title: String?
    var suggestions: [SMSuggestion<V>]
    
    static func ==(_ lhs: SMSuggestionGroup<V>, _ rhs: SMSuggestionGroup<V>) -> Bool {
        return lhs.suggestions == rhs.suggestions
    }
}

struct SuggestionInput<V: Equatable>: View {
    @Binding var text: String
    var suggestionGroups: [SMSuggestionGroup<V>]
    
    @StateObject var model = SuggestionsModel<V>()
    
    var body: some View {
        let model = self.model
        if model.suggestionGroups != self.suggestionGroups {
            model.suggestionGroups = self.suggestionGroups
            
            model.selectedSuggestion = nil
        }
        model.textBinding = self.$text
        
        return SuggestionTextField(text: self.$text, model: model)
            .borderlessWindow(isVisible: Binding<Bool>(get: { model.suggestionsVisible && !model.suggestionGroups.isEmpty }, set: { model.suggestionsVisible = $0 }),
                              behavior: .transient,
                              anchor: .bottomLeading,
                              windowAnchor: .topLeading,
                              windowOffset: CGPoint(x: -20, y: -16)) {
                SuggestionPopup(model: model)
                    .frame(width: model.width)
                    .background(VisualEffectBlur(material: .popover, blendingMode: .behindWindow, cornerRadius: 8))
//                    .visualEffect(.adaptive(.windowBackground))
//                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(lineWidth: 1)
                            .foregroundColor(Color(white: 0.6, opacity: 0.2))
                )
                .shadow(color: Color(white: 0, opacity: 0.10),
                        radius: 5, x: 0, y: 2)
                .padding(20)
            }
    }
}

//struct SuggestionInput_Previews: PreviewProvider {
//    static var previews: some View {
//        SuggestionInput()
//    }
//}
