import UIKit
import Display

/// Small, semantic Kislap palette for brand and status accents.
///
/// Structural surfaces and primary actions continue to use Telegram's active
/// presentation theme so Kislap screens feel native in light, dark and custom
/// themes. These tokens keep the few product-specific accents consistent.
enum KislapBrandPalette {
    static let midnight = UIColor(rgb: 0x07123B)
    static let brandPurple = UIColor(rgb: 0x7C52F4)
    static let brandCoral = UIColor(rgb: 0xFF5F6D)
    static let brandGold = UIColor(rgb: 0xFFBD3E)

    static let connection = UIColor.systemBlue
    static let success = UIColor.systemGreen
    static let caution = UIColor.systemOrange
    static let dating = UIColor.systemPink
}
