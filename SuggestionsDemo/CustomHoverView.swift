//
//  CustomHoverView.swift
//  SuggestionsDemo
//
//  Created by Stephan Michels on 17.12.20.
//

import SwiftUI

extension View {
    public func onCustomHover(perform action: @escaping (Bool) -> Void) -> some View {
        return CustomHoverView(perform: action, content: self)
    }
}

/*private struct CustomHoverView: NSViewRepresentable {
    private let action: (Bool) -> Void
    
    init(perform action: @escaping (Bool) -> Void) {
        self.action = action
    }
    
    func makeNSView(context: Context) -> NativeCustomHoverView {
        return NativeCustomHoverView(frame: .zero)
    }
    
    func updateNSView(_ view: NativeCustomHoverView, context: Context) {
        view.action = self.action
    }
}

private class NativeCustomHoverView: NSView {
    fileprivate var action: ((Bool) -> Void)?
    
    func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.mouseMoved, .activeAlways, .inVisibleRect]
        self.addTrackingArea(NSTrackingArea.init(rect: .zero, options: options, owner: self, userInfo: nil))
    }
    
    override func mouseEntered(with event: NSEvent) {
        self.action?(true)
    }
    
    override func mouseExited(with event: NSEvent) {
        self.action?(false)
    }
}*/

struct CustomHoverView<Content>: NSViewRepresentable where Content: View {
    private let action: (Bool) -> Void
    private let content: Content
    
    init(perform action: @escaping (Bool) -> Void, content: Content) {
        self.action = action
        self.content = content
    }
    
    func makeNSView(context: Context) -> NSHostingView<Content> {
        return NativeCustomHoverView(perform: self.action, rootView: self.content)
    }
    
    func updateNSView(_ nsView: NSHostingView<Content>, context: Context) {
    }
}

class NativeCustomHoverView<Content>: NSHostingView<Content> where Content : View {
    private let action: (Bool) -> Void
    
    init(perform action: @escaping (Bool) -> Void, rootView: Content) {
        self.action = action
        
        super.init(rootView: rootView)
        
        self.setupTrackingArea()
    }
    
    required init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.mouseMoved, .activeAlways, .inVisibleRect]
        self.addTrackingArea(NSTrackingArea.init(rect: .zero, options: options, owner: self, userInfo: nil))
    }
        
    override func mouseEntered(with event: NSEvent) {
        self.action(true)
    }
    
    override func mouseExited(with event: NSEvent) {
        self.action(false)
    }
}
