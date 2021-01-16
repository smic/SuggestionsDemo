//
//  BorderlessWindow.swift
//  SMChemSketchSwiftCore
//
//  Created by Stephan Michels on 03.07.20.
//  Copyright © 2020 Stephan Michels. All rights reserved.
//

import SwiftUI
import Combine

extension CGRect {
    fileprivate func point(anchor: UnitPoint) -> CGPoint {
        var point = self.origin
        point.x += self.size.width * anchor.x
        #if os(macOS)
        point.y += self.size.height * (1 - anchor.y)
        #else
        point.y += self.size.height * anchor.y
        #endif
        return point
    }
}

// inspired by https://gist.github.com/wtsnz/09e5fbbeb9d803e02bd9d3d6c14adcb5

public enum BorderlessWindowBehavior {
    /// Your application assumes responsibility for closing the popover.
    case applicationDefined
    
    /// The view will close the window when the user interacts with a user interface element outside the window.
    case transient
    
    /// The view will close the popover when the user interacts with user interface elements in the window containing the popover's positioning view.
    case semitransient
}

#if os(macOS)
public class MyWindow: NSWindow {
    
}

public struct BorderlessWindow<Content>: NSViewRepresentable where Content: View {
    @Binding private var isVisible: Bool
    private var behavior: BorderlessWindowBehavior
    private let anchor: UnitPoint
    private let windowAnchor: UnitPoint
    private let windowOffset: CGPoint
    private let content: () -> Content
    
    public init(isVisible: Binding<Bool>,
                behavior: BorderlessWindowBehavior = .applicationDefined,
                anchor: UnitPoint = .center,
                windowAnchor: UnitPoint = .center,
                windowOffset: CGPoint = .zero,
                @ViewBuilder content: @escaping () -> Content) {
        self._isVisible = isVisible
        self.behavior = behavior
        self.anchor = anchor
        self.windowAnchor = windowAnchor
        self.windowOffset = windowOffset
        self.content = content
    }
    
    public func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }
    
    public func updateNSView(_ view: NSView,
                             context: Context) {
        context.coordinator.hostingViewController.rootView = AnyView(self.content())
        
        let window = context.coordinator.window
        
        // Ensure that the visiblity has changed
        let isVisible = self.isVisible
        if isVisible != window.isVisible {
            if isVisible {
                if let parentWindow = view.window {
                    parentWindow.addChildWindow(window, ordered: .above)
                }
                window.makeKeyAndOrderFront(nil)
                
                window.alphaValue = 1.0
            } else {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.1
                    context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
                    window.animator().alphaValue = 0.0
                } completionHandler: {
                    if let parentWindow = view.window {
                        parentWindow.removeChildWindow(window)
                    }
                    window.orderOut(nil)
                }
            }
        }
        
        // set position of the window
        var viewFrame = view.convert(view.bounds, to: nil)
        viewFrame = view.window?.convertToScreen(viewFrame) ?? viewFrame
        let viewPoint = viewFrame.point(anchor: self.anchor)

        var windowFrame = window.frame
        let windowPoint = windowFrame.point(anchor: self.windowAnchor)
        
        var shift: CGPoint = viewPoint
        let windowOffset = self.windowOffset
        shift.x += windowOffset.x
        shift.y -= windowOffset.y
        shift.x -= windowPoint.x
        shift.y -= windowPoint.y
        
        if !shift.equalTo(.zero) {
            windowFrame.origin.x += shift.x
            windowFrame.origin.y += shift.y
            window.setFrame(windowFrame, display: false)
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, NSWindowDelegate {
        private var parent: BorderlessWindow
        
        fileprivate let window: NSWindow
        fileprivate let hostingViewController: NSHostingController<AnyView>
        private var localMouseDownEventMonitor: Any?
        private var didResizeSubscription: AnyCancellable?
        
        fileprivate init(_ parent: BorderlessWindow) {
            self.parent = parent
            
            let window = NSWindow(contentRect: .zero,
                                  styleMask: [.borderless],
                                  backing: .buffered,
                                  defer: true)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hidesOnDeactivate = true
            window.isExcludedFromWindowsMenu = true
            window.isReleasedWhenClosed = false
            self.window = window
            
            let hostingViewController = NSHostingController(rootView: AnyView(EmptyView()))
            window.contentViewController = hostingViewController
            self.hostingViewController = hostingViewController
            
            super.init()
            
            window.delegate = self
            
            let behaviour = self.parent.behavior
            if behaviour != .applicationDefined {
                self.localMouseDownEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] (event) -> NSEvent? in
                    guard let self = self else {
                        return event
                    }
                    
                    if !self.window.isVisible {
                        return event
                    }
                    
                    // If the mouse event is in the suggestion window, then there is nothing to do.
                    if event.window != self.window {
                        if behaviour == .semitransient {
                            if event.window != self.window.parent {
                                self.parent.isVisible = false
                                return nil
                            }
                        } else {
                            self.parent.isVisible = false
                            return nil
                        }
                    }
                    
                    return event
                }
            }
        }        
    }
}
#else
public struct BorderlessWindow<Content>: UIViewRepresentable where Content: View {
    @Binding private var isVisible: Bool
    private let anchor: UnitPoint
    private var behavior: BorderlessWindowBehavior
    private let windowAnchor: UnitPoint
    private let windowOffset: CGPoint
    private let content: () -> Content
    
    public init(isVisible: Binding<Bool>,
                behavior: BorderlessWindowBehavior = .applicationDefined,
                anchor: UnitPoint = .center,
                windowAnchor: UnitPoint = .center,
                windowOffset: CGPoint = .zero,
                @ViewBuilder content: @escaping () -> Content) {
        self._isVisible = isVisible
        self.behavior = behavior
        self.anchor = anchor
        self.windowAnchor = windowAnchor
        self.windowOffset = windowOffset
        self.content = content
    }
    
    public func makeUIView(context: Context) -> UIView {
        UIView(frame: .zero)
    }
    
    public func updateUIView(_ view: UIView,
                             context: Context) {
        let hostingViewController = context.coordinator.hostingViewController
        hostingViewController.rootView = AnyView(self.content().statusBar(hidden: true).edgesIgnoringSafeArea(.all))
        
        let window = context.coordinator.window
        
        // Ensure that the visiblity has changed
        let isVisible = self.isVisible
        if isVisible == window.isHidden {
            if isVisible {
                if let scene = view.window?.windowScene,
                   window.windowScene !== scene {
                    window.windowScene = scene
                }
                window.makeKeyAndVisible()
            } else {
                window.resignKey()
                window.isHidden = true
            }
        }
        
        // set position of the window
        var viewFrame = view.convert(view.bounds, to: nil)
        viewFrame = view.window?.convert(viewFrame, to: nil) ?? viewFrame
        let viewPoint = viewFrame.point(anchor: self.anchor)
        
        var windowFrame = window.frame
        windowFrame.size = hostingViewController.sizeThatFits(in: view.window?.bounds.size ?? .zero)
        
        let windowPoint = windowFrame.point(anchor: self.windowAnchor)
        
        var shift: CGPoint = viewPoint
        let windowOffset = self.windowOffset
        shift.x += windowOffset.x
        shift.y += windowOffset.y
        shift.x -= windowPoint.x
        shift.y -= windowPoint.y
        
        windowFrame.origin.x += shift.x
        windowFrame.origin.y += shift.y
        
        if !window.frame.equalTo(windowFrame) {
            window.frame = windowFrame
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject {
        private var parent: BorderlessWindow
        
        fileprivate let window: UIWindow
        fileprivate let hostingViewController: UIHostingController<AnyView>
        
        fileprivate init(_ parent: BorderlessWindow) {
            self.parent = parent
            
            let window = UIWindow(frame: .zero)
            window.windowLevel = .alert
            window.isOpaque = false
            window.backgroundColor = .clear
            window.canResizeToFitContent = true
            self.window = window
            
            let hostingViewController = UIHostingController(rootView: AnyView(EmptyView().statusBar(hidden: true).edgesIgnoringSafeArea(.all)))
            hostingViewController.view.backgroundColor = .clear
            window.rootViewController = hostingViewController
            self.hostingViewController = hostingViewController
        }
    }
}
#endif

extension View {
    public func borderlessWindow<Content: View>(isVisible: Binding<Bool>,
                                                behavior: BorderlessWindowBehavior = .applicationDefined,
                                                anchor: UnitPoint = .center,
                                                windowAnchor: UnitPoint = .center,
                                                windowOffset: CGPoint = .zero,
                                                @ViewBuilder content: @escaping () -> Content) -> some View {
        self.background(BorderlessWindow(isVisible: isVisible,
                                         behavior: behavior,
                                         anchor: anchor,
                                         windowAnchor: windowAnchor,
                                         windowOffset: windowOffset,
                                         content: content))
    }
}
