import SwiftUI

extension Color {
  init(hex: String) {
    var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    string = string.replacingOccurrences(of: "#", with: "")
    var rgb: UInt64 = 0
    Scanner(string: string).scanHexInt64(&rgb)
    let red = Double((rgb >> 16) & 0xFF) / 255.0
    let green = Double((rgb >> 8) & 0xFF) / 255.0
    let blue = Double(rgb & 0xFF) / 255.0
    self.init(red: red, green: green, blue: blue)
  }
}
