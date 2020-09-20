//
//  ForceEmphasizedView.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 20.09.20.
//

import SwiftUI

struct ForceEmphasizedView<Content>: NSViewRepresentable where Content: View {
    
    let content: Content
    
    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content()
    }
    
    func makeNSView(context: Context) -> NSView {
        NSHostingView<Content>(rootView: self.content)
    }
    
    func updateNSView(_ view: NSView, context: Context) {
        for superview in sequence(first: view, next: { $0.superview }) {
            if let rowView = superview as? NSTableRowView {
                if !rowView.isEmphasized {
                    rowView.isEmphasized = true
                }
                break
            }
        }
    }
}

struct ForceEmphasizedView_Previews: PreviewProvider {
    static var previews: some View {
        ForceEmphasizedView {
            Text("Hello World!")
        }
    }
}
