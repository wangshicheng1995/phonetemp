//
//  PhoneTempWidgetLiveActivity.swift
//  PhoneTempWidget
//
//  Created by Echo Wang on 2025/7/15.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PhoneTempWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct PhoneTempWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PhoneTempWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension PhoneTempWidgetAttributes {
    fileprivate static var preview: PhoneTempWidgetAttributes {
        PhoneTempWidgetAttributes(name: "World")
    }
}

extension PhoneTempWidgetAttributes.ContentState {
    fileprivate static var smiley: PhoneTempWidgetAttributes.ContentState {
        PhoneTempWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: PhoneTempWidgetAttributes.ContentState {
         PhoneTempWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: PhoneTempWidgetAttributes.preview) {
   PhoneTempWidgetLiveActivity()
} contentStates: {
    PhoneTempWidgetAttributes.ContentState.smiley
    PhoneTempWidgetAttributes.ContentState.starEyes
}
