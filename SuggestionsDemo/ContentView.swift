//
//  ContentView.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 16.09.20.
//

import SwiftUI

struct ContentView: View {
    @StateObject var model = DictionaryModel()
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 40) {
                if let currentTranslation = self.model.currentTranslation {
                    Text(self.model.currentText)
                    Image(systemName: "arrow.right")
                    Text(currentTranslation)
                }
            }
            .font(.title)
            .frame(height: 300)

            SuggestionInput(text: self.$model.currentText,
                            suggestions: self.model.suggestions)
                .frame(width: 300)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
