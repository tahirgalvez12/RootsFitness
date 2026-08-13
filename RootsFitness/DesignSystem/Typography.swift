import SwiftUI

/// Rounded-design type scale for the athletic, confident RootsFitness tone.
/// Use these instead of bare `.font(.largeTitle)` etc. so every screen
/// shares one consistent scale.
extension Font {
    static let rfDisplay = Font.system(size: 40, weight: .black, design: .rounded)
    static let rfLargeTitle = Font.system(size: 32, weight: .heavy, design: .rounded)
    static let rfTitle = Font.system(size: 22, weight: .bold, design: .rounded)
    static let rfHeadline = Font.system(size: 17, weight: .bold, design: .rounded)
    static let rfBody = Font.system(size: 16, weight: .medium, design: .rounded)
    static let rfSubheadline = Font.system(size: 14, weight: .semibold, design: .rounded)
    static let rfCaption = Font.system(size: 12, weight: .semibold, design: .rounded)
    static let rfButton = Font.system(size: 17, weight: .bold, design: .rounded)
}
