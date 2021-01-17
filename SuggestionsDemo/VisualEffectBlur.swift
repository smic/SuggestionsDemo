/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The macOS implementation of a NSVisualEffectView's blur.
*/

import SwiftUI

// MARK: - VisualEffectBlur

public struct VisualEffectBlur: View {
	private let material: NSVisualEffectView.Material
	private let blendingMode: NSVisualEffectView.BlendingMode
	private let cornerRadius: CGFloat
    
    public init(material: NSVisualEffectView.Material = .headerView,
				blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
				cornerRadius: CGFloat = 0) {
        self.material = material
		self.blendingMode = blendingMode
		self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
		Representable(material: self.material,
					  blendingMode: self.blendingMode,
					  cornerRadius: self.cornerRadius)
            .accessibility(hidden: true)
    }
}

// MARK: - Representable

extension VisualEffectBlur {
    struct Representable: NSViewRepresentable {
        var material: NSVisualEffectView.Material
		var blendingMode: NSVisualEffectView.BlendingMode
		var cornerRadius: CGFloat
		
		func maskImage(cornerRadius: CGFloat) -> NSImage? {
			guard cornerRadius > 0 else {
				return nil
			}
			let edgeLength = 2.0 * cornerRadius + 1.0
			let maskImage = NSImage(size: NSSize(width: edgeLength, height: edgeLength), flipped: false) { rect in
				let bezierPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
				NSColor.black.set()
				bezierPath.fill()
				return true
			}
			maskImage.capInsets = NSEdgeInsets(top: cornerRadius, left: cornerRadius, bottom: cornerRadius, right: cornerRadius)
			maskImage.resizingMode = .stretch
			return maskImage
		}
        
        func makeNSView(context: Context) -> NSVisualEffectView {
//            context.coordinator.visualEffectView
			return NSVisualEffectView()
        }
        
        func updateNSView(_ view: NSVisualEffectView, context: Context) {
//            context.coordinator.update(material: material)
			view.material = self.material
			view.blendingMode = self.blendingMode
			
//			view.maskImage = self.maskImage(cornerRadius: self.cornerRadius)
			view.wantsLayer = true
			view.layer?.cornerRadius = self.cornerRadius
			view.layer?.masksToBounds = true
        }
        
//        func makeCoordinator() -> Coordinator {
//            Coordinator()
//        }
    }
    
    /*class Coordinator {
        let visualEffectView = NSVisualEffectView()
        
        func update(material: NSVisualEffectView.Material) {
			visualEffectView.material = material
			visualEffectView.blendingMode = blendingMode
        }
    }*/
}

// MARK: - Previews

struct VisualEffectView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.red, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
            
			VisualEffectBlur(blendingMode: .withinWindow)
                .padding()
            
            Text("Hello World!")
        }
        .frame(width: 200, height: 100)
        .previewLayout(.sizeThatFits)
    }
}
