//
//  DebugView.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 19.09.20.
//

import SwiftUI

struct DebugView: NSViewRepresentable {
    let block: (NSView) -> Void
    
    init(_ block: @escaping (NSView) -> Void) {
        self.block = block
    }
    
    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }
    
    func updateNSView(_ view: NSView, context: Context) {
        self.block(view)
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView { view in
            print("frame: \(view.frame)")
        }
        .frame(width: 200, height: 300)
    }
}
