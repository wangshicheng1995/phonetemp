//
//  PhoneTempWidgetBundle.swift
//  PhoneTempWidget
//
//  Created by Echo Wang on 2025/7/15.
//

import WidgetKit
import SwiftUI

@main
struct PhoneTempWidgetBundle: WidgetBundle {
    var body: some Widget {
        PhoneTempWidget()
        PhoneTempWidgetControl()
        PhoneTempWidgetLiveActivity()
    }
}
