//
//  SuggestionInput.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 13.12.20.
//

import SwiftUI

struct SuggestionInput: View {
    @Binding var text: String
    var suggestions: [SMSuggestion]
    
    @StateObject var model = SuggestionsModel()
    
    var body: some View {
        let model = self.model
        if model.suggestions.count != self.suggestions.count {
            model.suggestions = self.suggestions
            
            model.selectedSuggestionIndex = nil
        }
        
        return SuggestionTextField(text: self.$text, model: model)
            .borderlessWindow(isVisible: Binding<Bool>(get: { model.suggestionsVisible && !model.suggestions.isEmpty }, set: { model.suggestionsVisible = $0 }),
                              behavior: .transient,
                              anchor: .bottomLeading,
                              windowAnchor: .topLeading,
                              windowOffset: CGPoint(x: -20 - 12, y: -16)) {
                SuggestionsView(text: self.$text, model: model)
                    .frame(width: model.width + 2 * 12)
                .visualEffect()
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5)
                            .stroke(lineWidth: 1)
                            .foregroundColor(Color(white: 0.6, opacity: 0.2)))
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
