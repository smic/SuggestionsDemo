//
//  Log.swift
//  Elements
//
//  Created by Stephan Michels on 08.03.20.
//  Copyright © 2020 Stephan Michels. All rights reserved.
//

import SwiftUI

struct LogModifier: ViewModifier {
    let text: String
    func body(content: Content) -> some View {
        print(text)
        return content
            .onAppear {}
    }
}

extension View {
    func log(_ text: String) -> some View {
        self.modifier(LogModifier(text: text))
    }
}
